import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

/// Exchange rates published by the provider: how much of each currency one
/// unit of [base] buys. Mid-market rates, with no buy or sell margin.
final class FxRates extends Equatable {
  const FxRates({
    required this.base,
    required this.rates,
    required this.updatedAt,
    required this.nextUpdateAt,
  });

  /// Always `USD` for Ecuador.
  final String base;

  /// Units of each currency (ISO code) per one [base].
  final Map<String, double> rates;

  /// When the provider published these rates.
  final DateTime updatedAt;

  /// When the provider will publish new ones (asking before is pointless).
  final DateTime nextUpdateAt;

  @override
  List<Object?> get props => [base, rates, updatedAt, nextUpdateAt];
}

enum FxSource { cache, network }

/// Rates on screen, where they came from and whether they are being
/// refreshed.
final class FxSnapshot extends Equatable {
  const FxSnapshot({
    required this.rates,
    required this.fetchedAt,
    required this.source,
    this.isRefreshing = false,
    this.refreshFailure,
  });

  final FxRates rates;

  /// When this device got them from the provider.
  final DateTime fetchedAt;
  final FxSource source;

  /// Newer rates are being requested; these are shown meanwhile.
  final bool isRefreshing;

  /// Why the saved rates could not be refreshed, if that failed.
  final Failure? refreshFailure;

  FxSnapshot copyWith({bool? isRefreshing, Failure? refreshFailure}) {
    return FxSnapshot(
      rates: rates,
      fetchedAt: fetchedAt,
      source: source,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshFailure: refreshFailure ?? this.refreshFailure,
    );
  }

  @override
  List<Object?> get props => [
    rates,
    fetchedAt,
    source,
    isRefreshing,
    refreshFailure,
  ];
}

/// Exchange rates for the app, from a public provider.
abstract interface class FxRatesRepository {
  /// Stale-while-revalidate: the saved rates right away (if any), then the
  /// provider's when the saved ones are outdated or [forceRefresh] is set.
  ///
  /// A failed refresh keeps the saved rates and reports why
  /// ([FxSnapshot.refreshFailure]); with nothing saved it is a `Left`.
  Stream<Either<Failure, FxSnapshot>> watchRates({bool forceRefresh = false});
}
