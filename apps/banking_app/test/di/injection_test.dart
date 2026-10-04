import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/app/session_effects.dart';
import 'package:banking_app/di/injection.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fakes.dart';

/// Registrations are lazy, so nothing here touches Firebase.
void main() {
  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());

  group('configureDependencies', () {
    test('dev registers the app graph and the debug tooling', () {
      configureDependencies(
        AppConfig.dev,
        keyValueStore: InMemoryKeyValueStore(),
      );

      expect(getIt<AppConfig>(), AppConfig.dev);
      expect(getIt.isRegistered<KeyValueStore>(), isTrue);
      expect(getIt.isRegistered<AuthRepository>(), isTrue);
      expect(getIt.isRegistered<OnboardingRepository>(), isTrue);
      expect(getIt.isRegistered<SessionCubit>(), isTrue);
      expect(getIt.isRegistered<GoRouter>(), isTrue);
      expect(getIt.isRegistered<AccountsRepository>(), isTrue);
      expect(getIt.isRegistered<SessionEffects>(), isTrue);
      expect(getIt.isRegistered<PersonalizationCubit>(), isTrue);
      expect(getIt.isRegistered<ChaosController>(), isTrue);
      expect(getIt.isRegistered<FirestoreNetworkSwitch>(), isTrue);
      expect(getIt.isRegistered<DebugTools>(), isTrue);
    });

    test('prod has no debug tooling', () {
      configureDependencies(
        AppConfig.prod,
        keyValueStore: InMemoryKeyValueStore(),
      );

      expect(getIt<AppConfig>(), AppConfig.prod);
      // Its own router, without the debug panel route.
      expect(getIt.isRegistered<GoRouter>(), isTrue);
      expect(getIt.isRegistered<ChaosController>(), isFalse);
      expect(getIt.isRegistered<FirestoreNetworkSwitch>(), isFalse);
      expect(getIt.isRegistered<DebugTools>(), isFalse);
    });
  });
}
