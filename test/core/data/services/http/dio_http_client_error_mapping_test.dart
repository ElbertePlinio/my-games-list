import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/data/services/http/dio_http_client.dart';
import 'package:picklog/core/domain/models/api_error.dart';
import 'package:picklog/core/domain/models/api_response.dart';

/// Adapter that throws a fixed [DioException] for every request, driving the
/// non-`badResponse` branches of `DioHttpClient._handleError`.
class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.build);

  final DioException Function(RequestOptions options) build;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw build(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter that returns a fixed status code and body, driving the `badResponse`
/// branch (Dio throws because the default `validateStatus` rejects >= 400).
class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.statusCode, {this.body = '{}'});

  final int statusCode;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  DioHttpClient clientWith(HttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local/'))
      ..httpClientAdapter = adapter;
    return DioHttpClient(dio: dio);
  }

  /// Runs a request and returns the mapped error (fails if it succeeds).
  ///
  /// Uses POST on purpose: `RetryInterceptor` only retries idempotent GETs, so
  /// POST exercises `_handleError` directly with no backoff delays. The mapping
  /// itself is method-agnostic.
  Future<ApiError> errorFor(HttpClientAdapter adapter) async {
    final ApiResponse<dynamic> res = await clientWith(
      adapter,
    ).post<dynamic>('/games', data: <String, dynamic>{});
    expect(res.isError, isTrue, reason: 'expected a failure response');
    return res.error!;
  }

  DioException dioError(
    RequestOptions options,
    DioExceptionType type, {
    Response<dynamic>? response,
  }) {
    return DioException(
      requestOptions: options,
      type: type,
      response: response,
    );
  }

  group('DioHttpClient._handleError — connection/network exception types', () {
    test('connectionTimeout maps to error.network.timeout (408)', () async {
      final error = await errorFor(
        _ThrowingAdapter(
          (o) => dioError(o, DioExceptionType.connectionTimeout),
        ),
      );

      expect(error.errorCode, 'error.network.timeout');
      expect(error.statusCode, 408);
      expect(error.userMessage, contains('Connection timeout'));
    });

    test('sendTimeout maps to error.network.timeout (408)', () async {
      final error = await errorFor(
        _ThrowingAdapter((o) => dioError(o, DioExceptionType.sendTimeout)),
      );

      expect(error.errorCode, 'error.network.timeout');
      expect(error.statusCode, 408);
    });

    test('receiveTimeout maps to error.network.timeout (408)', () async {
      final error = await errorFor(
        _ThrowingAdapter((o) => dioError(o, DioExceptionType.receiveTimeout)),
      );

      expect(error.errorCode, 'error.network.timeout');
      expect(error.statusCode, 408);
    });

    test('cancel maps to error.network.cancelled (499)', () async {
      final error = await errorFor(
        _ThrowingAdapter((o) => dioError(o, DioExceptionType.cancel)),
      );

      expect(error.errorCode, 'error.network.cancelled');
      expect(error.statusCode, 499);
      expect(error.userMessage, contains('Request was cancelled'));
    });

    test('connectionError maps to error.network.connection (0)', () async {
      final error = await errorFor(
        _ThrowingAdapter((o) => dioError(o, DioExceptionType.connectionError)),
      );

      expect(error.errorCode, 'error.network.connection');
      expect(error.statusCode, 0);
      expect(error.userMessage, contains('No internet connection'));
    });

    test('badCertificate maps to error.network.certificate (495)', () async {
      final error = await errorFor(
        _ThrowingAdapter((o) => dioError(o, DioExceptionType.badCertificate)),
      );

      expect(error.errorCode, 'error.network.certificate');
      expect(error.statusCode, 495);
      expect(error.userMessage, contains('Security certificate error'));
    });

    test('unknown maps to error.unknown (500)', () async {
      final error = await errorFor(
        _ThrowingAdapter((o) => dioError(o, DioExceptionType.unknown)),
      );

      expect(error.errorCode, 'error.unknown');
      expect(error.statusCode, 500);
    });
  });

  group('DioHttpClient._handleError — badResponse by status code', () {
    test('400 maps to error.api.bad_request', () async {
      final error = await errorFor(_ResponseAdapter(400));

      expect(error.errorCode, 'error.api.bad_request');
      expect(error.statusCode, 400);
      expect(error.userMessage, contains('Bad request'));
    });

    test('401 maps to error.auth.unauthorized', () async {
      final error = await errorFor(_ResponseAdapter(401));

      expect(error.errorCode, 'error.auth.unauthorized');
      expect(error.statusCode, 401);
    });

    test('403 maps to error.auth.forbidden', () async {
      final error = await errorFor(_ResponseAdapter(403));

      expect(error.errorCode, 'error.auth.forbidden');
      expect(error.statusCode, 403);
    });

    test('404 maps to error.api.not_found', () async {
      final error = await errorFor(_ResponseAdapter(404));

      expect(error.errorCode, 'error.api.not_found');
      expect(error.statusCode, 404);
    });

    test('500 maps to error.api.server_error', () async {
      final error = await errorFor(_ResponseAdapter(500));

      expect(error.errorCode, 'error.api.server_error');
      expect(error.statusCode, 500);
    });

    test('unmapped 4xx (418) falls back to error.api.unknown', () async {
      final error = await errorFor(_ResponseAdapter(418));

      expect(error.errorCode, 'error.api.unknown');
      expect(error.statusCode, 418);
    });

    test('unmapped 5xx (503) falls back to error.api.unknown', () async {
      final error = await errorFor(_ResponseAdapter(503));

      expect(error.errorCode, 'error.api.unknown');
      expect(error.statusCode, 503);
    });
  });

  group('DioHttpClient._handleError — badResponse body parsing', () {
    test('standardized error JSON is parsed via ApiError.fromJson', () async {
      final error = await errorFor(
        _ResponseAdapter(
          400,
          body:
              '{"name":"Validation Error","message":"Password is too short",'
              '"action":"Use at least 6 characters","status_code":422,'
              '"error_code":"error.validation.password.too_short"}',
        ),
      );

      expect(error.errorCode, 'error.validation.password.too_short');
      expect(error.statusCode, 422);
      expect(error.name, 'Validation Error');
      expect(error.message, 'Password is too short');
    });

    test('body with only a message key is parsed via fromJson', () async {
      final error = await errorFor(
        _ResponseAdapter(400, body: '{"message":"Something broke"}'),
      );

      expect(error.message, 'Something broke');
      // fromJson defaults the code when absent.
      expect(error.errorCode, 'error.unknown');
    });

    test('legacy {"error": "..."} body maps to error.api.unknown', () async {
      final error = await errorFor(
        _ResponseAdapter(400, body: '{"error":"Old style failure"}'),
      );

      expect(error.errorCode, 'error.api.unknown');
      expect(error.message, 'Old style failure');
      expect(error.statusCode, 400);
    });

    test(
      'badResponse with a non-map body falls back to generic error',
      () async {
        final error = await errorFor(
          _ResponseAdapter(500, body: '"plain text"'),
        );

        expect(error.errorCode, 'error.api.server_error');
        expect(error.statusCode, 500);
      },
    );
  });
}
