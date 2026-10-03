import 'package:core/src/network/chaos/chaos_config.dart';
import 'package:core/src/network/chaos/chaos_interceptor.dart';
import 'package:core/src/network/retry_interceptor.dart';
import 'package:dio/dio.dart';

/// Builds the HTTP client used for external APIs.
///
/// Interceptor order: [RetryInterceptor] first, then [ChaosInterceptor] (only
/// when [chaos] is given, i.e. in dev). dio runs error handlers in this same
/// order, so injected failures reach the retry logic.
Dio createDioClient({
  required String baseUrl,
  RetryPolicy retryPolicy = const RetryPolicy(),
  ChaosController? chaos,
  Duration connectTimeout = const Duration(seconds: 10),
  Duration receiveTimeout = const Duration(seconds: 10),
  List<Interceptor> interceptors = const [],
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    ),
  );
  dio.interceptors.addAll([
    RetryInterceptor(dio: dio, policy: retryPolicy),
    if (chaos != null) ChaosInterceptor(controller: chaos),
    ...interceptors,
  ]);
  return dio;
}
