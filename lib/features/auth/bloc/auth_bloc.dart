import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:picklog/core/data/services/storage/local_storage_service.dart';
import 'package:picklog/core/services/session_reset_service.dart';
import 'package:picklog/features/auth/bloc/auth_event.dart';
import 'package:picklog/features/auth/bloc/auth_state.dart';
import 'package:picklog/features/auth/user_model.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._storageService, this._sessionReset)
    : super(const AuthInitial()) {
    on<AuthStateLoaded>(_onAuthStateLoaded);
    on<AuthUserAuthenticated>(_onAuthUserAuthenticated);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }
  final LocalStorageService _storageService;
  final SessionResetService _sessionReset;
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentUserKey = 'current_user';

  Future<void> _onAuthStateLoaded(
    AuthStateLoaded event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final loggedIn = await _storageService.getBool(_isLoggedInKey) ?? false;
      final userJson = await _storageService.getString(_currentUserKey);

      if (loggedIn && userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = User.fromJson(userMap);
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      await _clearAuthState();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthUserAuthenticated(
    AuthUserAuthenticated event,
    Emitter<AuthState> emit,
  ) async {
    await _saveAuthState(event.user);
    emit(AuthAuthenticated(event.user));
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _sessionReset.teardownSession();
    } catch (_) {
      // Logout must always proceed even if session teardown fails.
    }
    await _clearAuthState();
    emit(const AuthUnauthenticated());
  }

  Future<void> _saveAuthState(User user) async {
    await _storageService.setBool(_isLoggedInKey, true);
    final userJson = jsonEncode(user.toJson());
    await _storageService.setString(_currentUserKey, userJson);
  }

  Future<void> _clearAuthState() async {
    await _storageService.remove(_isLoggedInKey);
    await _storageService.remove(_currentUserKey);
  }
}
