import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/features/auth/auth_response.dart';
import 'package:picklog/features/auth/domain/social_auth_request.dart';
import 'package:picklog/features/auth/sign_in/sign_in_request.dart';
import 'package:picklog/features/auth/sign_up/sign_up_request.dart';
import 'package:picklog/core/data/services/storage/token_storage.dart';

/// Implementation of AuthRepository that handles authentication operations
/// using the HTTP client and local storage.
class AuthRepository {
  AuthRepository({
    required IHttpClient httpClient,
    required TokenStorage tokenStorage,
  }) : _httpClient = httpClient,
       _tokenStorage = tokenStorage;
  final IHttpClient _httpClient;
  final TokenStorage _tokenStorage;

  Future<AuthResponse> signIn(SignInRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '/auth/signin',
      data: request.toJson(),
    );

    if (response.isError) {
      throw Exception(response.error?.userMessage ?? 'Sign in failed');
    }

    return _persistAuthResponse(AuthResponse.fromJson(response.dataOrThrow));
  }

  Future<AuthResponse> signUp(SignUpRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '/auth/signup',
      data: request.toJson(),
    );

    if (response.isError) {
      throw Exception(response.error?.userMessage ?? 'Sign up failed');
    }

    return _persistAuthResponse(AuthResponse.fromJson(response.dataOrThrow));
  }

  /// google_sign_in 7.x requires initialize() to run exactly once before use.
  static Future<void>? _googleSignInInit;

  /// Authenticates with Google. [consentVersion] is the Privacy Policy / Terms
  /// version the user accepted on the auth screen; the API requires it on
  /// `/auth/social` for account creation.
  ///
  /// Mobile uses the native account picker (google_sign_in) — reliable, and it
  /// avoids the flaky web-redirect sign-in page. Web keeps Firebase's popup
  /// provider flow, since google_sign_in's authenticate() isn't supported there.
  Future<AuthResponse> signInWithGoogle({
    required String consentVersion,
  }) async {
    try {
      final firebaseIdToken = kIsWeb
          ? await _firebaseIdTokenViaPopup()
          : await _firebaseIdTokenViaNativeGoogle();
      return await _exchangeFirebaseToken(
        'google',
        firebaseIdToken,
        consentVersion,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Sign-in cancelled.');
      }
      throw Exception('Google sign-in failed. Please try again.');
    } catch (e) {
      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  /// Native Android/iOS account picker → Google ID token → Firebase credential.
  /// The server (web) client id is read from google-services.json's
  /// `default_web_client_id`, so the ID token's audience is one Firebase accepts.
  Future<String> _firebaseIdTokenViaNativeGoogle() async {
    _googleSignInInit ??= GoogleSignIn.instance.initialize();
    await _googleSignInInit;

    final account = await GoogleSignIn.instance.authenticate();
    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null) {
      throw Exception('Failed to get Google ID token');
    }

    final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) throw Exception('Failed to get Firebase ID token');
    return idToken;
  }

  /// Web: Firebase popup-based Google provider flow.
  Future<String> _firebaseIdTokenViaPopup() async {
    final userCredential = await FirebaseAuth.instance.signInWithProvider(
      GoogleAuthProvider(),
    );
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) throw Exception('Failed to get Firebase ID token');
    return idToken;
  }

  /// Exchanges a Firebase ID token for an app JWT by calling POST /auth/social.
  Future<AuthResponse> _exchangeFirebaseToken(
    String provider,
    String idToken,
    String consentVersion,
  ) async {
    final request = SocialAuthRequest(
      provider: provider,
      firebaseIdToken: idToken,
      consentVersion: consentVersion,
    );

    final response = await _httpClient.post<Map<String, dynamic>>(
      '/auth/social',
      data: request.toJson(),
    );

    if (response.isError) {
      throw Exception(response.error?.userMessage ?? 'Social sign-in failed');
    }

    return _persistAuthResponse(AuthResponse.fromJson(response.dataOrThrow));
  }

  /// Persists the auth token to local storage and the HTTP client.
  Future<AuthResponse> _persistAuthResponse(AuthResponse authResponse) async {
    await saveToken(authResponse.token);
    _httpClient.setAuthToken(authResponse.token);
    return authResponse;
  }

  Future<void> saveToken(String token) async {
    await _tokenStorage.write(token);
  }

  Future<String?> getToken() => _tokenStorage.read();

  Future<void> clearToken() async {
    await _tokenStorage.delete();
    _httpClient.clearAuthToken();
  }

  /// Permanently deletes the authenticated user's account via DELETE /users/me.
  /// On success the backend returns 204 with no body; the caller is responsible
  /// for tearing down the local session afterwards.
  Future<void> deleteAccount() async {
    final response = await _httpClient.delete<void>('/users/me');

    if (response.isError) {
      throw Exception(response.error?.userMessage ?? 'Account deletion failed');
    }
  }

  /// Fetches the authenticated user's data export via GET /users/me/export and
  /// returns it as pretty-printed JSON ready to be saved or shared.
  Future<String> exportData() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '/users/me/export',
    );

    if (response.isError) {
      throw Exception(response.error?.userMessage ?? 'Data export failed');
    }

    return const JsonEncoder.withIndent('  ').convert(response.dataOrThrow);
  }
}
