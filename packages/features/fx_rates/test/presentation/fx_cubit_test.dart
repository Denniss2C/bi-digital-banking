import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fx_rates/fx_rates.dart';
import 'package:fx_rates/src/presentation/fx_cubit.dart';

import '../helpers.dart';

void main() {
  blocTest<FxCubit, FxState>(
    'shows the saved rates, then the fresh ones',
    build: () => FxCubit(
      FakeFxRatesRepository([
        Right(snapshot(eur: 0.80, source: FxSource.cache)),
        Right(snapshot()),
      ]),
    ),
    expect: () => [
      FxLoaded(snapshot(eur: 0.80, source: FxSource.cache)),
      FxLoaded(snapshot()),
    ],
  );

  blocTest<FxCubit, FxState>(
    'no rates at all is an error, and retry asks the provider',
    build: () => FxCubit(FakeFxRatesRepository([const Left(NetworkFailure())])),
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      (cubit.repository as FakeFxRatesRepository).events = [Right(snapshot())];
      await cubit.retry();
    },
    expect: () => [
      const FxError(NetworkFailure()),
      const FxLoading(),
      FxLoaded(snapshot()),
    ],
    verify: (cubit) => expect(
      (cubit.repository as FakeFxRatesRepository).forced,
      [false, true],
    ),
  );

  test('refresh forces a request and completes when it answers', () async {
    final repository = FakeFxRatesRepository([Right(snapshot())]);
    final cubit = FxCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    await expectLater(cubit.refresh(), completes);

    expect(repository.forced, [false, true]);
  });
}
