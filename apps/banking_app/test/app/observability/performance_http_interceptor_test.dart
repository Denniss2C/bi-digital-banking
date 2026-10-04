import 'dart:convert';
import 'dart:typed_data';

import 'package:banking_app/app/observability/performance_http_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPerformance extends Mock implements FirebasePerformance {}

class _MockHttpMetric extends Mock implements HttpMetric {}

/// Answers every request with [statusCode].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({'ok': statusCode < 400}),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() => registerFallbackValue(HttpMethod.Get));

  late _MockPerformance performance;
  late _MockHttpMetric metric;

  Dio client(int statusCode) => Dio(BaseOptions(baseUrl: 'https://api.example'))
    ..httpClientAdapter = _FakeAdapter(statusCode)
    ..interceptors.add(PerformanceHttpInterceptor(performance));

  setUp(() {
    performance = _MockPerformance();
    metric = _MockHttpMetric();
    when(() => performance.newHttpMetric(any(), any())).thenReturn(metric);
    when(() => metric.start()).thenAnswer((_) async {});
    when(() => metric.stop()).thenAnswer((_) async {});
  });

  test('measures a call with its method, URL and status', () async {
    await client(200).get<Object?>('/v6/latest/USD');

    verify(
      () => performance.newHttpMetric(
        'https://api.example/v6/latest/USD',
        HttpMethod.Get,
      ),
    ).called(1);
    verify(() => metric.start()).called(1);
    verify(() => metric.httpResponseCode = 200).called(1);
    verify(() => metric.stop()).called(1);
  });

  test('a failed call is measured too, with its status', () async {
    await expectLater(
      client(503).get<Object?>('/v6/latest/USD'),
      throwsA(isA<DioException>()),
    );

    verify(() => metric.httpResponseCode = 503).called(1);
    verify(() => metric.stop()).called(1);
  });
}
