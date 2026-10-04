import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/session_effects.dart';
import 'package:banking_app/di/injection.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fakes.dart';

void main() {
  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());

  group('configureDependencies', () {
    test('dev registers the app graph and the ChaosController', () {
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
      expect(getIt.isRegistered<ChaosController>(), isTrue);
    });

    test('prod has no debug tooling', () {
      configureDependencies(
        AppConfig.prod,
        keyValueStore: InMemoryKeyValueStore(),
      );

      expect(getIt<AppConfig>(), AppConfig.prod);
      expect(getIt.isRegistered<ChaosController>(), isFalse);
    });
  });
}
