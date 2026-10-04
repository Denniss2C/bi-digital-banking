import 'dart:convert';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fx_rates/fx_rates.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  group('parseLatestRates', () {
    test('reads the base, the rates and the publication times', () {
      final rates = parseLatestRates(apiPayload());

      expect(rates, sampleRates());
    });

    test('drops entries that are not positive numbers', () {
      final payload = apiPayload()
        ..['rates'] = {'EUR': 0.9, 'BAD': 'x', 'ZERO': 0};

      expect(parseLatestRates(payload).rates, {'EUR': 0.9});
    });

    test('rejects an error answer or a malformed one', () {
      expect(
        () => parseLatestRates({'result': 'error', 'error-type': 'quota'}),
        throwsFormatException,
      );
      expect(
        () => parseLatestRates(apiPayload()..remove('rates')),
        throwsFormatException,
      );
      expect(
        () => parseLatestRates(apiPayload()..remove('time_next_update_unix')),
        throwsFormatException,
      );
    });
  });

  group('ExchangeRateApiRepository', () {
    late _MockDio dio;
    late InMemoryKeyValueStore store;
    late DateTime now;

    // Before the provider publishes again: the cache is current.
    final beforeNextUpdate = DateTime.utc(2026, 10, 4, 15);
    // After it published again.
    final afterNextUpdate = DateTime.utc(2026, 10, 5, 3);

    ExchangeRateApiRepository build() =>
        ExchangeRateApiRepository(dio: dio, store: store, clock: () => now);

    void answer(Map<String, Object?> payload) =>
        when(
          () => dio.get<Map<String, Object?>>(
            ExchangeRateApiRepository.latestPath,
          ),
        ).thenAnswer(
          (_) async => Response(
            data: payload,
            statusCode: 200,
            requestOptions: RequestOptions(
              path: ExchangeRateApiRepository.latestPath,
            ),
          ),
        );

    void fail() =>
        when(
          () => dio.get<Map<String, Object?>>(
            ExchangeRateApiRepository.latestPath,
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(
              path: ExchangeRateApiRepository.latestPath,
            ),
          ),
        );

    void saveCache({required DateTime fetchedAt}) =>
        store.values[ExchangeRateApiRepository.cacheKey] = jsonEncode({
          'fetchedAt': fetchedAt.millisecondsSinceEpoch,
          'payload': apiPayload(eur: 0.80),
        });

    void verifyCalls(int times) {
      final calls = verify(
        () =>
            dio.get<Map<String, Object?>>(ExchangeRateApiRepository.latestPath),
      );
      times == 0 ? calls.called(0) : calls.called(times);
    }

    setUp(() {
      dio = _MockDio();
      store = InMemoryKeyValueStore();
      now = beforeNextUpdate;
    });

    test('without a cache it asks the provider and saves the answer', () async {
      answer(apiPayload());

      final events = await build().watchRates().toList();

      expect(events, [
        Right<Failure, FxSnapshot>(
          FxSnapshot(
            rates: sampleRates(),
            fetchedAt: now,
            source: FxSource.network,
          ),
        ),
      ]);
      expect(store.values, contains(ExchangeRateApiRepository.cacheKey));
    });

    test('without a cache and without network it is a failure', () async {
      fail();

      final events = await build().watchRates().toList();

      expect(events.single.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('a current cache is shown and the provider is not called', () async {
      saveCache(fetchedAt: beforeNextUpdate.subtract(const Duration(hours: 2)));

      final events = await build().watchRates().toList();

      final snapshot = events.single.getRight().toNullable()!;
      expect(snapshot.source, FxSource.cache);
      expect(snapshot.isRefreshing, isFalse);
      expect(snapshot.rates.rates['EUR'], 0.80);
      verifyNever(() => dio.get<Map<String, Object?>>(any()));
    });

    test('an outdated cache is shown first, then the fresh rates', () async {
      now = afterNextUpdate;
      saveCache(fetchedAt: beforeNextUpdate);
      answer(apiPayload());

      final events = await build().watchRates().toList();

      final cached = events.first.getRight().toNullable()!;
      final fresh = events.last.getRight().toNullable()!;
      expect(cached.source, FxSource.cache);
      expect(cached.isRefreshing, isTrue);
      expect(fresh.source, FxSource.network);
      expect(fresh.rates.rates['EUR'], 0.8888);
    });

    test('never asks more than once an hour, as the provider asks', () async {
      now = afterNextUpdate;
      saveCache(
        fetchedAt: afterNextUpdate.subtract(const Duration(minutes: 30)),
      );

      final events = await build().watchRates().toList();

      expect(events.single.getRight().toNullable()!.isRefreshing, isFalse);
      verifyNever(() => dio.get<Map<String, Object?>>(any()));
    });

    test('forceRefresh asks even when the cache is current', () async {
      saveCache(fetchedAt: beforeNextUpdate);
      answer(apiPayload());

      final events = await build().watchRates(forceRefresh: true).toList();

      expect(events, hasLength(2));
      verifyCalls(1);
    });

    test('a failed refresh keeps the cache and says why', () async {
      now = afterNextUpdate;
      saveCache(fetchedAt: beforeNextUpdate);
      fail();

      final events = await build().watchRates().toList();

      final last = events.last.getRight().toNullable()!;
      expect(last.source, FxSource.cache);
      expect(last.isRefreshing, isFalse);
      expect(last.refreshFailure, isA<NetworkFailure>());
      expect(last.rates.rates['EUR'], 0.80);
    });

    test('a corrupt cache is ignored and replaced', () async {
      store.values[ExchangeRateApiRepository.cacheKey] = '{not json';
      answer(apiPayload());

      final events = await build().watchRates().toList();

      expect(events.single.getRight().toNullable()!.source, FxSource.network);
    });

    test('an invalid answer from the provider is a server failure', () async {
      answer({'result': 'error', 'error-type': 'quota-reached'});

      final events = await build().watchRates().toList();

      expect(events.single.getLeft().toNullable(), isA<ServerFailure>());
    });
  });
}
