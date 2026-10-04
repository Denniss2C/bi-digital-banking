import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fx_rates/fx_rates.dart';

/// Published at 2026-10-04 00:02 UTC, next update 2026-10-05 00:30 UTC.
Map<String, Object?> apiPayload({double eur = 0.8888}) => {
  'result': 'success',
  'base_code': 'USD',
  'time_last_update_unix': 1791072152,
  'time_next_update_unix': 1791160222,
  'rates': {
    'USD': 1,
    'EUR': eur,
    'COP': 3311.644334,
    'PEN': 3.443349,
    'MXN': 18.214153,
  },
};

final publishedAt = DateTime.fromMillisecondsSinceEpoch(
  1791072152 * 1000,
  isUtc: true,
);
final nextUpdateAt = DateTime.fromMillisecondsSinceEpoch(
  1791160222 * 1000,
  isUtc: true,
);

FxRates sampleRates({double eur = 0.8888}) => FxRates(
  base: 'USD',
  rates: {
    'USD': 1,
    'EUR': eur,
    'COP': 3311.644334,
    'PEN': 3.443349,
    'MXN': 18.214153,
  },
  updatedAt: publishedAt,
  nextUpdateAt: nextUpdateAt,
);

class InMemoryKeyValueStore implements KeyValueStore {
  final values = <String, Object?>{};

  @override
  T? read<T>(String key) => values[key] as T?;

  @override
  Future<void> write<T>(String key, T value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

extension PumpFx on WidgetTester {
  Future<void> pumpLocalized(Widget child) async {
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: FxLocalizations.localizationsDelegates,
        supportedLocales: FxLocalizations.supportedLocales,
        home: child,
      ),
    );
    await pumpAndSettle();
  }
}

/// Repository whose stream the test controls; records forced refreshes.
class FakeFxRatesRepository implements FxRatesRepository {
  FakeFxRatesRepository(this.events);

  /// What each call to [watchRates] emits, in order.
  List<Either<Failure, FxSnapshot>> events;
  final forced = <bool>[];

  @override
  Stream<Either<Failure, FxSnapshot>> watchRates({bool forceRefresh = false}) {
    forced.add(forceRefresh);
    return Stream.fromIterable(events);
  }
}

FxSnapshot snapshot({
  double eur = 0.8888,
  FxSource source = FxSource.network,
  Failure? refreshFailure,
}) => FxSnapshot(
  rates: sampleRates(eur: eur),
  fetchedAt: DateTime.utc(2026, 10, 4, 15),
  source: source,
  refreshFailure: refreshFailure,
);
