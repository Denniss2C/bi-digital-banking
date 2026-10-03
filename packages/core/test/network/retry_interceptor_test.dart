import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/network_test_helpers.dart';

void main() {
  group('RetryInterceptor', () {
    test('retries a transient 503 and returns the next response', () async {
      final adapter = FakeHttpAdapter([503, 200]);
      final delay = RecordingDelay();
      final dio = buildTestDio(adapter: adapter, delay: delay);

      final response = await dio.get<dynamic>('/rates');

      expect(response.statusCode, 200);
      expect(adapter.requests, 2);
      expect(delay.calls, hasLength(1));
    });

    test('gives up after maxAttempts and surfaces the last error', () async {
      final adapter = FakeHttpAdapter([503, 503, 503]);
      final delay = RecordingDelay();
      final dio = buildTestDio(adapter: adapter, delay: delay);

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
      expect(adapter.requests, 3);
      expect(delay.calls, hasLength(2));
    });

    test('retries connection errors and timeouts', () async {
      final adapter = FakeHttpAdapter([
        DioExceptionType.connectionError,
        DioExceptionType.receiveTimeout,
        200,
      ]);
      final dio = buildTestDio(adapter: adapter);

      final response = await dio.get<dynamic>('/rates');

      expect(response.statusCode, 200);
      expect(adapter.requests, 3);
    });

    test('does not retry client errors such as 404', () async {
      final adapter = FakeHttpAdapter([404]);
      final delay = RecordingDelay();
      final dio = buildTestDio(adapter: adapter, delay: delay);

      await expectLater(
        dio.get<dynamic>('/missing'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, 1);
      expect(delay.calls, isEmpty);
    });

    test('never retries a non-idempotent POST', () async {
      final adapter = FakeHttpAdapter([503]);
      final dio = buildTestDio(adapter: adapter);

      await expectLater(
        dio.post<dynamic>('/transfers', data: {'amount': 10}),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, 1);
    });
  });

  group('RetryPolicy.backoff', () {
    const policy = RetryPolicy(
      baseDelay: Duration(milliseconds: 100),
      maxDelay: Duration(milliseconds: 300),
    );

    test('doubles the cap on every retry and applies jitter', () {
      final random = SequenceRandom([0.5]);

      expect(policy.backoff(1, random), const Duration(milliseconds: 50));
      expect(policy.backoff(2, random), const Duration(milliseconds: 100));
    });

    test('never exceeds maxDelay', () {
      final random = SequenceRandom([1]);

      expect(policy.backoff(3, random), const Duration(milliseconds: 300));
      expect(policy.backoff(8, random), const Duration(milliseconds: 300));
    });

    test('jitter spreads waits between zero and the cap', () {
      expect(policy.backoff(2, SequenceRandom([0])), Duration.zero);
      expect(
        policy.backoff(2, SequenceRandom([0.25])),
        const Duration(milliseconds: 50),
      );
    });
  });
}
