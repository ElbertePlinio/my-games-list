import 'package:picklog/core/domain/models/api_response.dart';

/// Interface for HTTP client operations.
/// This abstraction allows for easy swapping of HTTP implementations
/// (e.g., from Dio to http package) without affecting the rest of the codebase.
abstract class IHttpClient {
  /// Performs a GET request to the specified [path].
  ///
  /// [queryParameters] are optional query parameters to append to the URL.
  /// Returns an [ApiResponse] with the response data or error.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  /// Performs a POST request to the specified [path].
  ///
  /// [data] is the request body.
  /// [queryParameters] are optional query parameters to append to the URL.
  /// Returns an [ApiResponse] with the response data or error.
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });

  /// Performs a PUT request to the specified [path].
  ///
  /// [data] is the request body.
  /// [queryParameters] are optional query parameters to append to the URL.
  /// Returns an [ApiResponse] with the response data or error.
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });

  /// Performs a PATCH request to the specified [path].
  ///
  /// [data] is the request body.
  /// [queryParameters] are optional query parameters to append to the URL.
  /// Returns an [ApiResponse] with the response data or error.
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });

  /// Performs a DELETE request to the specified [path].
  ///
  /// [queryParameters] are optional query parameters to append to the URL.
  /// Returns an [ApiResponse] with the response data or error.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  /// Sets the authorization header with the provided [token].
  void setAuthToken(String token);

  /// Clears the authorization header.
  void clearAuthToken();

  /// Registers a callback invoked when a request fails with a 401 that looks
  /// like an expired/invalid session. The callback returns `true` if it acted
  /// on it (e.g. triggered logout), so the client only suppresses further 401s
  /// once a logout is actually scheduled. Pass null to clear it.
  void setOnUnauthorized(bool Function()? callback);
}
