import 'package:accounts/accounts.dart';
import 'package:sdui/sdui.dart';

/// Components the home can render: the standard ones from `sdui` plus the
/// ones each feature contributes. Features never know about each other; only
/// the shell puts them together.
SduiRegistry createHomeRegistry({
  required AccountsRepository accountsRepository,
  required String userId,
}) {
  return SduiRegistry(standardSduiComponents)..registerAll(
    accountsSduiComponents(repository: accountsRepository, userId: userId),
  );
}
