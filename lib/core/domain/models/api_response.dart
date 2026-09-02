import 'package:equatable/equatable.dart';
import 'package:picklog/core/domain/models/api_error.dart';

/// Generic API response wrapper that handles both success and error cases.
/// This provides type safety and consistent error handling across the application.
class ApiResponse<T> extends Equatable {
  const ApiResponse._({this.data, this.error, required this.isSuccess});

  /// Creates a successful response with data.
  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  /// Creates an error response with an ApiError.
  factory ApiResponse.failure(ApiError error) {
    return ApiResponse._(error: error, isSuccess: false);
  }

  final T? data;
  final ApiError? error;
  final bool isSuccess;

  /// Returns true if the response is an error.
  bool get isError => !isSuccess;

  /// Returns the data if successful, otherwise throws an exception with the error message.
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception(error?.userMessage ?? 'Unknown error occurred');
  }

  @override
  List<Object?> get props => [data, error, isSuccess];
}
