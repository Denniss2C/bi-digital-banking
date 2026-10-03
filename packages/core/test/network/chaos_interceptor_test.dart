import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/network_test_helpers.dart';

void main() {
  const noRetry = RetryPolicy(maxAttempts: 1);

  group('ChaosInterceptor', () {
    test('passes requests through when disabled', () async {
      final adapter = FakeHttpAdapter([200]);
      final dio = buildTestDio(adapter: adapter, chaos: ChaosController());

      final response = await dio.get<dynamic>('/rates');

      expect(response.statusCode, 200);
      expect(adapter.requests, 1);
    });

    test(
      'offline mode fails as a connection error without a request',
      () async {
        final adapter = FakeHttpAdapter([200]);
        final chaos = ChaosController(
          const ChaosConfig(enabled: true, offline: true),
        );
        final dio = buildTestDio(
          adapter: adapter,
          chaos: chaos,
          policy: noRetry,
        );

        await expectLater(
          dio.get<dynamic>('/rates'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.connectionError,
            ),
          ),
        );
        expect(adapter.requests, 0);
      },
    );

    test('failureRate 1 always injects an HTTP 503', () async {
      final adapter = FakeHttpAdapter([200]);
      final chaos = ChaosController(
        const ChaosConfig(enabled: true, failureRate: 1),
      );
      final dio = buildTestDio(adapter: adapter, chaos: chaos, policy: noRetry);

      await expectLater(
        dio.get<dynamic>('/rates'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
      expect(adapter.requests, 0);
    });

    test('adds the configured latency before the request', () async {
      final adapter = FakeHttpAdapter([200]);
      final delay = RecordingDelay();
      final chaos = ChaosController(
        const ChaosConfig(enabled: true, latency: Duration(milliseconds: 800)),
      );
      final dio = buildTestDio(adapter: adapter, chaos: chaos, delay: delay);

      await dio.get<dynamic>('/rates');

      expect(delay.calls, [const Duration(milliseconds: 800)]);
      expect(adapter.requests, 1);
    });

    test('reads the config on every request (runtime changes)', () async {
      final adapter = FakeHttpAdapter([200]);
      final chaos = ChaosController(
        const ChaosConfig(enabled: true, offline: true),
      );
      final dio = buildTestDio(adapter: adapter, chaos: chaos, policy: noRetry);

      await expectLater(
        dio.get<dynamic>('/rates'),
        throwsA(isA<DioException>()),
      );

      chaos.value = chaos.value.copyWith(offline: false);
      final response = await dio.get<dynamic>('/rates');

      expect(response.statusCode, 200);
    });
  });

  group('ChaosInterceptor with RetryInterceptor', () {
    test('injected failures are retried like real ones', () async {
      final adapter = FakeHttpAdapter([200]);
      final delay = RecordingDelay();
      final chaos = ChaosController(
        const ChaosConfig(enabled: true, failureRate: 0.5),
      );
      final dio = buildTestDio(
        adapter: adapter,
        chaos: chaos,
        // 1st attempt: 0.1 < 0.5 -> injected 503; 2nd attempt: 0.9 -> passes.
        chaosRandom: SequenceRandom([0.1, 0.9]),
        delay: delay,
      );

      final response = await dio.get<dynamic>('/rates');

      expect(response.statusCode, 200);
      expect(adapter.requests, 1);
      expect(delay.calls, hasLength(1), reason: 'one retry backoff');
    });

    test('offline mode exhausts the retries and then fails', () async {
      final adapter = FakeHttpAdapter([200]);
      final delay = RecordingDelay();
      final chaos = ChaosController(
        const ChaosConfig(enabled: true, offline: true),
      );
      final dio = buildTestDio(adapter: adapter, chaos: chaos, delay: delay);

      await expectLater(
        dio.get<dynamic>('/rates'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, 0);
      expect(delay.calls, hasLength(2), reason: '3 attempts = 2 backoffs');
    });
  });

  group('createDioClient', () {
    test('adds the ChaosInterceptor only when a controller is given', () {
      final prod = createDioClient(baseUrl: 'https://api.test');
      final dev = createDioClient(
        baseUrl: 'https://api.test',
        chaos: ChaosController(),
      );

      expect(prod.interceptors.whereType<RetryInterceptor>(), hasLength(1));
      expect(prod.interceptors.whereType<ChaosInterceptor>(), isEmpty);
      expect(dev.interceptors.whereType<ChaosInterceptor>(), hasLength(1));
    });
  });
}
