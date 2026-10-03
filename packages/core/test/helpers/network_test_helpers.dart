import 'dart:math';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';

/// Scripted HTTP backend: each request consumes the next outcome, either an
/// HTTP status code (`int`) or a [DioExceptionType] raised before a response.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(List<Object> outcomes) : _outcomes = List.of(outcomes);

  final List<Object> _outcomes;

  /// Requests that actually reached the "server".
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_outcomes.isEmpty) {
      throw StateError('No scripted outcome left for ${options.uri}');
    }
    requests++;
    final outcome = _outcomes.removeAt(0);
    if (outcome is DioExceptionType) {
      throw DioException(requestOptions: options, type: outcome);
    }
    return ResponseBody.fromString(
      '{"ok": true}',
      outcome as int,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// [Random] that returns a fixed sequence of doubles (cycling).
class SequenceRandom implements Random {
  SequenceRandom(this._values);

  final List<double> _values;
  int _index = 0;

  @override
  double nextDouble() => _values[_index++ % _values.length];

  @override
  int nextInt(int max) => (nextDouble() * max).floor();

  @override
  bool nextBool() => nextDouble() < 0.5;
}

/// Records every requested wait instead of sleeping.
class RecordingDelay {
  final List<Duration> calls = [];

  Future<void> call(Duration duration) async => calls.add(duration);
}

/// Same interceptor stack as `createDioClient`, with injectable randomness
/// and delays so tests are deterministic and instant.
Dio buildTestDio({
  required FakeHttpAdapter adapter,
  RetryPolicy policy = const RetryPolicy(),
  ChaosController? chaos,
  Random? retryRandom,
  Random? chaosRandom,
  RecordingDelay? delay,
}) {
  final recorder = delay ?? RecordingDelay();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll([
    RetryInterceptor(
      dio: dio,
      policy: policy,
      random: retryRandom ?? SequenceRandom([0.5]),
      delay: recorder.call,
    ),
    if (chaos != null)
      ChaosInterceptor(
        controller: chaos,
        random: chaosRandom ?? SequenceRandom([0.5]),
        delay: recorder.call,
      ),
  ]);
  return dio;
}
