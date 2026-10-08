import 'package:picklog/core/domain/models/api_error.dart';

/// Coarse error categories that the UI maps to localized messages.
///
/// Blocs store a kind instead of `e.toString()`, so raw English or stack
/// text never reaches the screen.
enum AppErrorKind {
  /// The device could not reach the server (timeout, DNS, no connection).
  network,

  /// The requested item does not exist.
  notFound,

  /// The session is missing, expired or not allowed.
  unauthorized,

  /// The server failed.
  server,

  /// Anything else.
  unknown;

  /// Maps any thrown object to a kind.
  static AppErrorKind from(Object error) {
    final apiError = error is ApiException ? error.error : null;
    if (apiError == null) {
      return error is ApiError ? _fromApiError(error) : AppErrorKind.unknown;
    }
    return _fromApiError(apiError);
  }

  static AppErrorKind _fromApiError(ApiError error) {
    if (error.errorCode.startsWith('error.network')) {
      return AppErrorKind.network;
    }
    return switch (error.statusCode) {
      404 => AppErrorKind.notFound,
      401 || 403 => AppErrorKind.unauthorized,
      >= 500 => AppErrorKind.server,
      _ => AppErrorKind.unknown,
    };
  }
}

/// Exception thrown by repositories when an API call fails.
///
/// Keeps the structured [ApiError] so callers can map it to an
/// [AppErrorKind]. [toString] keeps the server message for logs.
class ApiException implements Exception {
  const ApiException(this.error, {this.fallbackMessage = 'Request failed'});

  final ApiError? error;
  final String fallbackMessage;

  @override
  String toString() => error?.userMessage ?? fallbackMessage;
}
