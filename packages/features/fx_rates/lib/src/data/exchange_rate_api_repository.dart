import 'dart:convert';
import 'dart:developer' as developer;

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fx_rates/src/domain/fx_rates.dart';

/// Parses the open access response of ExchangeRate-API (`/v6/latest/USD`).
/// Throws [FormatException] if it is not a successful, well-formed answer.
FxRates parseLatestRates(Map<String, Object?> json) {
  if (json['result'] != 'success') {
    throw FormatException('Provider error: ${json['error-type'] ?? 'unknown'}');
  }
  final base = json['base_code'];
  final rates = json['rates'];
  if (base is! String || rates is! Map<String, Object?>) {
    throw const FormatException('Missing base_code or rates');
  }
  DateTime unix(String key) => switch (json[key]) {
    final int seconds => DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ),
    _ => throw FormatException('Missing $key'),
  };
  return FxRates(
    base: base,
    rates: {
      for (final MapEntry(:key, :value) in rates.entries)
        if (value is num && value > 0) key: value.toDouble(),
    },
    updatedAt: unix('time_last_update_unix'),
    nextUpdateAt: unix('time_next_update_unix'),
  );
}

/// [FxRatesRepository] on ExchangeRate-API's open access endpoint (no key;
/// attribution required) with a device cache.
///
/// The provider publishes new rates once a day and asks not to call more
/// than once an hour, so the cache is used until it publishes again
/// (`time_next_update_unix`) and an hour has passed since the last call.
class ExchangeRateApiRepository implements FxRatesRepository {
  ExchangeRateApiRepository({
    required this.dio,
    required this.store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const baseUrl = 'https://open.er-api.com';
  static const latestPath = '/v6/latest/USD';
  static const cacheKey = 'fx_rates.latest';
  static const minRefreshInterval = Duration(hours: 1);

  final Dio dio;
  final KeyValueStore store;
  final DateTime Function() _clock;

  @override
  Stream<Either<Failure, FxSnapshot>> watchRates({
    bool forceRefresh = false,
  }) async* {
    final cached = _readCache();
    final now = _clock();
    final isDue =
        forceRefresh ||
        cached == null ||
        (now.isAfter(cached.rates.nextUpdateAt) &&
            now.difference(cached.fetchedAt) >= minRefreshInterval);

    if (cached != null) yield Right(cached.copyWith(isRefreshing: isDue));
    if (!isDue) return;

    final fetched = await _fetch();
    yield fetched.match(
      (failure) => cached == null
          ? Left(failure)
          : Right(
              cached.copyWith(isRefreshing: false, refreshFailure: failure),
            ),
      Right.new,
    );
  }

  Future<Either<Failure, FxSnapshot>> _fetch() async {
    try {
      final response = await dio.get<Map<String, Object?>>(latestPath);
      final payload = response.data ?? const <String, Object?>{};
      final snapshot = FxSnapshot(
        rates: parseLatestRates(payload),
        fetchedAt: _clock(),
        source: FxSource.network,
      );
      await store.write(
        cacheKey,
        jsonEncode({
          'fetchedAt': snapshot.fetchedAt.millisecondsSinceEpoch,
          'payload': payload,
        }),
      );
      return Right(snapshot);
    } on DioException catch (error) {
      return Left(mapDioException(error));
    } on FormatException catch (error) {
      return Left(ServerFailure(message: 'Invalid rates: ${error.message}'));
    }
  }

  FxSnapshot? _readCache() {
    final raw = store.read<String>(cacheKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return FxSnapshot(
        rates: parseLatestRates(json['payload']! as Map<String, Object?>),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(
          json['fetchedAt']! as int,
        ),
        source: FxSource.cache,
      );
    } on Object catch (error) {
      // A corrupt cache is treated as no cache; the next fetch rewrites it.
      developer.log('Ignored corrupt cache: $error', name: 'fx_rates');
      return null;
    }
  }
}
