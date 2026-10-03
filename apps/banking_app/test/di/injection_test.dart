import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/di/injection.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(() => getIt.reset());
  tearDown(() => getIt.reset());

  group('configureDependencies', () {
    test('dev registers the config, the router and the ChaosController', () {
      configureDependencies(AppConfig.dev);

      expect(getIt<AppConfig>(), AppConfig.dev);
      expect(getIt.isRegistered<GoRouter>(), isTrue);
      expect(getIt.isRegistered<ChaosController>(), isTrue);
    });

    test('prod has no debug tooling', () {
      configureDependencies(AppConfig.prod);

      expect(getIt<AppConfig>(), AppConfig.prod);
      expect(getIt.isRegistered<ChaosController>(), isFalse);
    });
  });
}
