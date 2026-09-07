import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/data/services/http/dio_http_client.dart';
import 'package:picklog/core/domain/models/api_response.dart';

/// Adapter that throws a fixed [DioException], used to model browser XHR
/// failures (CORS / opaque responses surface as `connectionError`).
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

/// Adapter that captures the outgoing request options so header attachment can
/// be asserted, then returns a successful empty body.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  DioHttpClient clientWith(HttpClientAdapter adapter, {Dio? dio}) {
    final client = dio ?? Dio(BaseOptions(baseUrl: 'http://test.local/'));
    client.httpClientAdapter = adapter;
    return DioHttpClient(dio: client);
  }

  group('DioHttpClient — web CORS / opaque XHR failures', () {
    test(
      'a CORS failure (connectionError with an opaque response) maps to '
      'error.network.connection (0) without throwing on the null status',
      () async {
        // A browser CORS rejection produces a connectionError. The XHR adapter
        // may attach an "opaque" response whose statusCode is null; the mapping
        // must not assume a numeric status here.
        final adapter = _ThrowingAdapter(
          (o) => DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
            message: 'XMLHttpRequest error (likely CORS or network)',
            response: Response<dynamic>(requestOptions: o, statusCode: null),
          ),
        );

        final ApiResponse<dynamic> res = await clientWith(
          adapter,
        ).post<dynamic>('/games', data: <String, dynamic>{});

        expect(res.isError, isTrue);
        expect(res.error!.errorCode, 'error.network.connection');
        expect(res.error!.statusCode, 0);
      },
    );

    test('a CORS failure with no response at all still maps to '
        'error.network.connection (0)', () async {
      final adapter = _ThrowingAdapter(
        (o) => DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
          message: 'XMLHttpRequest error',
        ),
      );

      final ApiResponse<dynamic> res = await clientWith(
        adapter,
      ).post<dynamic>('/games', data: <String, dynamic>{});

      expect(res.isError, isTrue);
      expect(res.error!.errorCode, 'error.network.connection');
      expect(res.error!.statusCode, 0);
    });
  });

  group('DioHttpClient — Authorization header attachment', () {
    test(
      'setAuthToken attaches a Bearer header to outgoing requests',
      () async {
        final capturing = _CapturingAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'http://test.local/'));
        final client = clientWith(capturing, dio: dio)..setAuthToken('abc123');

        await client.get<dynamic>('/games/recommendations');

        expect(
          capturing.lastRequest!.headers['Authorization'],
          'Bearer abc123',
        );
      },
    );

    test('clearAuthToken removes the Authorization header', () async {
      final capturing = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/'));
      final client = clientWith(capturing, dio: dio)
        ..setAuthToken('abc123')
        ..clearAuthToken();

      await client.get<dynamic>('/games/recommendations');

      expect(
        capturing.lastRequest!.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });
}
