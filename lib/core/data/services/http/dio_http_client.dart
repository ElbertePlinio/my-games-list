import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:picklog/core/data/services/http/i_http_client.dart';
import 'package:picklog/core/data/services/http/retry_interceptor.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';
import 'package:picklog/core/utils/env.dart';

/// Dio implementation of [IHttpClient].
/// Handles HTTP requests using the Dio package with proper error handling.
class DioHttpClient implements IHttpClient {
  DioHttpClient({Dio? dio}) {
    const baseUrl = Env.apiBaseUrl;

    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            contentType: 'application/json',
            headers: {'Accept': 'application/json'},
          ),
        );
    // Only log request/response bodies in debug builds — they can contain
    // auth tokens and personal data that must never be logged in release.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    // Auto-logout when an authenticated request fails with 401 (expired/invalid
    // session). Auth endpoints and unauthenticated requests are excluded.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (_shouldTriggerLogout(error)) {
            // Only latch once a logout is actually scheduled, so a 401 that
            // arrives before auth state is ready doesn't suppress later ones.
            final handled = _onUnauthorized?.call() ?? false;
            if (handled) _unauthorizedHandled = true;
          }
          handler.next(error);
        },
      ),
    );

    // Retry idempotent reads on transient network failures with backoff.
    _dio.interceptors.add(RetryInterceptor(_dio));
  }
  late final Dio _dio;
  bool Function()? _onUnauthorized;
  bool _unauthorizedHandled = false;

  static const List<String> _authPaths = [
    '/auth/signin',
    '/auth/signup',
    '/auth/social',
  ];

  /// Runs a Dio request and maps the result/errors into an [ApiResponse].
  Future<ApiResponse<T>> _request<T>(
    Future<Response<T>> Function() send,
  ) async {
    try {
      final response = await send();
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(_handleError(e));
    } catch (e) {
      return ApiResponse.failure(
        const ApiError(
          name: 'Unexpected Error',
          message: 'An unexpected error occurred',
          action: 'Please try again later',
          statusCode: 500,
          errorCode: 'error.unexpected',
        ),
      );
    }
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _request(() => _dio.get<T>(path, queryParameters: queryParameters));

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _request(
    () => _dio.post<T>(path, data: data, queryParameters: queryParameters),
  );

  @override
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _request(
    () => _dio.put<T>(path, data: data, queryParameters: queryParameters),
  );

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) => _request(
    () => _dio.patch<T>(path, data: data, queryParameters: queryParameters),
  );

  @override
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _request(() => _dio.delete<T>(path, queryParameters: queryParameters));

  @override
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    // A new session re-arms the one-shot auto-logout guard.
    _unauthorizedHandled = false;
  }

  @override
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  @override
  void setOnUnauthorized(bool Function()? callback) {
    _onUnauthorized = callback;
  }

  /// True when a 401 may indicate the current session expired: a non-auth
  /// request whose token matches the client's current token. The token match
  /// ignores stale 401s from a previous login; an authenticated-but-tokenless
  /// session (both null) still passes, and the callback decides via auth state.
  bool _shouldTriggerLogout(DioException error) {
    if (_unauthorizedHandled) return false;
    if (error.response?.statusCode != 401) return false;
    if (_authPaths.any(error.requestOptions.path.contains)) return false;

    final requestAuth =
        error.requestOptions.headers['Authorization'] as String?;
    final currentAuth = _dio.options.headers['Authorization'] as String?;
    return requestAuth == currentAuth;
  }

  /// Handles Dio errors and extracts ApiError from response.
  ApiError _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiError(
          name: 'Connection Timeout',
          message: 'Connection timeout',
          action: 'Please check your internet connection and try again',
          statusCode: 408,
          errorCode: 'error.network.timeout',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final data = error.response?.data;

        // Try to parse standardized error format from API
        if (data is Map<String, dynamic>) {
          // Check if it's our standardized error format
          if (data.containsKey('error_code') || data.containsKey('message')) {
            return ApiError.fromJson(data);
          }

          // Fallback: old format with just 'error' key
          if (data.containsKey('error')) {
            return ApiError(
              name: 'API Error',
              message: data['error'] as String,
              action: 'Please try again',
              statusCode: statusCode,
              errorCode: 'error.api.unknown',
            );
          }
        }

        // Generic error based on status code
        return _createGenericError(statusCode);

      case DioExceptionType.cancel:
        return const ApiError(
          name: 'Request Cancelled',
          message: 'Request was cancelled',
          action: 'Please try again if needed',
          statusCode: 499,
          errorCode: 'error.network.cancelled',
        );

      case DioExceptionType.connectionError:
        return const ApiError(
          name: 'Connection Error',
          message: 'No internet connection',
          action: 'Please check your network and try again',
          statusCode: 0,
          errorCode: 'error.network.connection',
        );

      case DioExceptionType.badCertificate:
        return const ApiError(
          name: 'Security Error',
          message: 'Security certificate error',
          action: 'Please contact support if this persists',
          statusCode: 495,
          errorCode: 'error.network.certificate',
        );

      case DioExceptionType.unknown:
        return const ApiError(
          name: 'Unknown Error',
          message: 'An unexpected error occurred',
          action: 'Please try again later',
          statusCode: 500,
          errorCode: 'error.unknown',
        );
    }
  }

  /// Creates a generic ApiError based on HTTP status code.
  ApiError _createGenericError(int statusCode) {
    switch (statusCode) {
      case 400:
        return const ApiError(
          name: 'Bad Request',
          message: 'Bad request',
          action: 'Please check your input and try again',
          statusCode: 400,
          errorCode: 'error.api.bad_request',
        );
      case 401:
        return const ApiError(
          name: 'Unauthorized',
          message: 'Unauthorized',
          action: 'Please sign in again',
          statusCode: 401,
          errorCode: 'error.auth.unauthorized',
        );
      case 403:
        return const ApiError(
          name: 'Forbidden',
          message: 'Forbidden',
          action: 'You do not have access to this resource',
          statusCode: 403,
          errorCode: 'error.auth.forbidden',
        );
      case 404:
        return const ApiError(
          name: 'Not Found',
          message: 'Resource not found',
          action: 'The requested resource could not be found',
          statusCode: 404,
          errorCode: 'error.api.not_found',
        );
      case 500:
        return const ApiError(
          name: 'Server Error',
          message: 'Server error',
          action: 'Please try again later',
          statusCode: 500,
          errorCode: 'error.api.server_error',
        );
      default:
        return ApiError(
          name: 'Error',
          message: 'An error occurred',
          action: 'Please try again',
          statusCode: statusCode,
          errorCode: 'error.api.unknown',
        );
    }
  }
}
