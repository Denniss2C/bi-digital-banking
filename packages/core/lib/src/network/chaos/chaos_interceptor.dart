import 'dart:math';

import 'package:core/src/network/chaos/chaos_config.dart';
import 'package:core/src/network/retry_interceptor.dart';
import 'package:dio/dio.dart';

/// Injects latency, HTTP 503 errors or a fake offline mode, following the
/// live config of a [ChaosController]. Register it only in dev builds.
class ChaosInterceptor extends Interceptor {
  ChaosInterceptor({
    required this.controller,
    Random? random,
    this.delay = _realDelay,
  }) : _random = random ?? Random();

  final ChaosController controller;
  final Delay delay;
  final Random _random;

  static Future<void> _realDelay(Duration duration) =>
      Future<void>.delayed(duration);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final config = controller.value;
    if (!config.enabled) return handler.next(options);

    if (config.latency > Duration.zero) await delay(config.latency);

    // `true` lets every interceptor's onError see the injected error, exactly
    // as with a real network error. Without it, RetryInterceptor would never
    // run and chaos would not exercise the retry logic.
    if (config.offline) {
      return handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'ChaosInterceptor: offline mode',
        ),
        true,
      );
    }

    if (_random.nextDouble() < config.failureRate) {
      return handler.reject(
        DioException.badResponse(
          statusCode: 503,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 503,
            statusMessage: 'ChaosInterceptor: injected failure',
          ),
        ),
        true,
      );
    }

    return handler.next(options);
  }
}
