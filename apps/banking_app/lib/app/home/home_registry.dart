import 'package:accounts/accounts.dart';
import 'package:fx_rates/fx_rates.dart';
import 'package:sdui/sdui.dart';

/// Components the home can render: the standard ones from `sdui` plus the
/// ones each feature contributes. Features never know about each other; only
/// the shell puts them together.
///
/// A feature turned off remotely does not register its components, so the
/// home skips them like any unknown type.
SduiRegistry createHomeRegistry({
  required AccountsRepository accountsRepository,
  required FxRatesRepository fxRatesRepository,
  required String userId,
  bool fxEnabled = true,
}) {
  return SduiRegistry(standardSduiComponents)
    ..registerAll(
      accountsSduiComponents(repository: accountsRepository, userId: userId),
    )
    ..registerAll(
      fxEnabled ? fxSduiComponents(repository: fxRatesRepository) : const {},
    );
}
