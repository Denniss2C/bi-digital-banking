import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Measures every HTTP call made with dio as a Performance `HttpMetric`
/// (duration, status code and size), per attempt: each retry is its own
/// call. Requests that the chaos mode rejects never leave the device and are
/// not measured.
class PerformanceHttpInterceptor extends Interceptor {
  PerformanceHttpInterceptor(this.performance);

  final FirebasePerformance performance;

  static const _metricKey = 'performance.httpMetric';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final metric = performance.newHttpMetric(
      options.uri.toString(),
      _method(options.method),
    );
    options.extra[_metricKey] = metric;
    unawaited(metric.start());
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _stop(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _stop(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _stop(RequestOptions options, int? statusCode) {
    final metric = options.extra.remove(_metricKey);
    if (metric is! HttpMetric) return;
    metric.httpResponseCode = statusCode;
    unawaited(metric.stop());
  }

  static HttpMethod _method(String method) => HttpMethod.values.firstWhere(
    (value) => value.name.toUpperCase() == method.toUpperCase(),
    orElse: () => HttpMethod.Get,
  );
}
