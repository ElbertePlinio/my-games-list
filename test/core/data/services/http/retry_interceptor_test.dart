import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/data/services/http/retry_interceptor.dart';

/// Adapter that fails the first [failTimes] calls (a connection error, or a
/// [failStatus] response) then returns 200, counting every call.
class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter({this.failTimes = 0, this.failStatus});

  final int failTimes;
  final int? failStatus;
  void Function(int call)? onFetch;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    onFetch?.call(calls);
    if (calls <= failTimes) {
      if (failStatus != null) {
        return ResponseBody.fromString(
          '{"error":true}',
          failStatus!,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_CountingAdapter adapter, {int maxRetries = 3}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(
      dio,
      maxRetries: maxRetries,
      backoff: (_) => Duration.zero,
    ),
  );
  return dio;
}

void main() {
  group('RetryInterceptor', () {
    test('retries a GET on a connection error then succeeds', () async {
      final adapter = _CountingAdapter(failTimes: 2);
      final dio = _dioWith(adapter);

      final response = await dio.get<dynamic>('/games');

      expect(response.statusCode, 200);
      expect(adapter.calls, 3); // 1 initial + 2 retries
    });

    test('retries a GET on a 503 then succeeds', () async {
      final adapter = _CountingAdapter(failTimes: 1, failStatus: 503);
      final dio = _dioWith(adapter);

      final response = await dio.get<dynamic>('/games');

      expect(response.statusCode, 200);
      expect(adapter.calls, 2);
    });

    test('retries a GET on a plain 500 then succeeds', () async {
      final adapter = _CountingAdapter(failTimes: 1, failStatus: 500);
      final dio = _dioWith(adapter);

      final response = await dio.get<dynamic>('/games');

      expect(response.statusCode, 200);
      expect(adapter.calls, 2);
    });

    test('does not retry when the session token changes mid-flight', () async {
      final adapter = _CountingAdapter(failTimes: 99);
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test',
          headers: {'Authorization': 'Bearer A'},
        ),
      )..httpClientAdapter = adapter;
      // Simulate a logout/login during the request: change the client's token
      // after the first attempt fails.
      adapter.onFetch = (call) {
        if (call == 1) dio.options.headers['Authorization'] = 'Bearer B';
      };
      dio.interceptors.add(
        RetryInterceptor(dio, backoff: (_) => Duration.zero),
      );

      await expectLater(
        dio.get<dynamic>('/games'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1); // not replayed with the stale token
    });

    test('does not retry a 404', () async {
      final adapter = _CountingAdapter(failTimes: 1, failStatus: 404);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.get<dynamic>('/games'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    });

    test('does not retry a non-GET (POST)', () async {
      final adapter = _CountingAdapter(failTimes: 1);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.post<dynamic>('/games/search'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    });

    test('stops after maxRetries and surfaces the error', () async {
      final adapter = _CountingAdapter(failTimes: 99);
      final dio = _dioWith(adapter, maxRetries: 2);

      await expectLater(
        dio.get<dynamic>('/games'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 3); // 1 initial + 2 retries
    });
  });
}
