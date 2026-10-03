import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// Service locator. Only the shell (composition root) reads from it directly;
/// features receive their dependencies through constructors.
final getIt = GetIt.instance;

/// Registers the running flavor's [config] and every injectable dependency.
///
/// The injectable environment is the flavor name, so `@dev` registrations
/// (such as the ChaosController) only exist in dev builds.
@InjectableInit(ignoreUnregisteredTypes: [AppConfig])
void configureDependencies(AppConfig config) {
  getIt
    ..registerSingleton<AppConfig>(config)
    ..init(environment: config.flavor.name);
}
