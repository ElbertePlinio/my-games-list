import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklog/core/data/services/http/dio_http_client.dart';

/// Adapter that returns a fixed status code for every request.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
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
  group('DioHttpClient auto-logout on 401', () {
    DioHttpClient buildClient(int status) {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local/'))
        ..httpClientAdapter = _StatusAdapter(status);
      return DioHttpClient(dio: dio);
    }

    test('a 401 on the current session triggers onUnauthorized once when '
        'handled', () async {
      var calls = 0;
      final client = buildClient(401)
        ..setOnUnauthorized(() {
          calls++;
          return true; // logout scheduled → latch
        })
        ..setAuthToken('token');

      await client.get<dynamic>('/games/recommendations');
      await client.get<dynamic>('/games/recommendations'); // suppressed

      expect(calls, 1);
    });

    test('does not latch when the callback reports it did not act', () async {
      var calls = 0;
      final client = buildClient(401)
        ..setOnUnauthorized(() {
          calls++;
          return false; // e.g. auth state not ready → not handled
        })
        ..setAuthToken('token');

      await client.get<dynamic>('/games/recommendations');
      await client.get<dynamic>('/games/recommendations'); // re-fires

      expect(calls, 2);
    });

    test('does not trigger on an auth-endpoint 401', () async {
      var calls = 0;
      final client = buildClient(401)
        ..setOnUnauthorized(() {
          calls++;
          return true;
        })
        ..setAuthToken('token');

      await client.post<dynamic>('/auth/signin', data: <String, dynamic>{});

      expect(calls, 0);
    });

    test('does not trigger on a non-401 error', () async {
      var calls = 0;
      final client = buildClient(500)
        ..setOnUnauthorized(() {
          calls++;
          return true;
        })
        ..setAuthToken('token');

      await client.get<dynamic>('/games/recommendations');

      expect(calls, 0);
    });
  });
}
