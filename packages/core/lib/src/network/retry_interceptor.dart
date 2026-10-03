import 'dart:math';

import 'package:dio/dio.dart';

/// Waits for [duration]; injectable so tests never sleep.
typedef Delay = Future<void> Function(Duration duration);

Future<void> _realDelay(Duration duration) => Future<void>.delayed(duration);

/// When and how often a failed request is retried.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 400),
    this.maxDelay = const Duration(seconds: 4),
    this.retryableStatusCodes = const {408, 429, 500, 502, 503, 504},
    this.retryableMethods = const {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'},
  }) : assert(maxAttempts >= 1, 'maxAttempts includes the first attempt');

  /// Total attempts, including the first one (3 = 1 request + 2 retries).
  final int maxAttempts;

  /// Backoff cap for the first retry; it doubles on every retry.
  final Duration baseDelay;

  /// Upper bound for any single wait.
  final Duration maxDelay;

  final Set<int> retryableStatusCodes;

  /// Only idempotent methods are retried, so a POST is never sent twice.
  final Set<String> retryableMethods;

  /// Whether [error] is transient and worth another attempt.
  bool isRetryable(DioException error) {
    final method = error.requestOptions.method.toUpperCase();
    if (!retryableMethods.contains(method)) return false;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        return retryableStatusCodes.contains(error.response?.statusCode);
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Exponential backoff with "full jitter": a random wait between zero and
  /// `min(maxDelay, baseDelay * 2^(retry - 1))`, so clients that failed at the
  /// same time do not retry in sync.
  Duration backoff(int retry, Random random) {
    final exponential = baseDelay * pow(2, retry - 1).toInt();
    final cap = exponential < maxDelay ? exponential : maxDelay;
    return cap * random.nextDouble();
  }
}

/// Retries transient failures following a [RetryPolicy].
///
/// Each retry goes through `dio.fetch`, so it passes through every
/// interceptor again (including the ChaosInterceptor in dev).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.policy = const RetryPolicy(),
    Random? random,
    this.delay = _realDelay,
  }) : _random = random ?? Random();

  /// Key in `RequestOptions.extra` with the attempt number (1-based).
  static const attemptKey = 'retry_attempt';

  /// The client that owns this interceptor; retries go through it again.
  final Dio dio;
  final RetryPolicy policy;
  final Delay delay;
  final Random _random;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = options.extra[attemptKey] as int? ?? 1;

    if (attempt >= policy.maxAttempts || !policy.isRetryable(err)) {
      return handler.next(err);
    }

    await delay(policy.backoff(attempt, _random));
    options.extra[attemptKey] = attempt + 1;

    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      // The nested fetch already ran its own retries; just propagate.
      return handler.next(retryError);
    }
  }
}
