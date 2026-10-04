import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/di/injection.config.dart';
import 'package:core/core.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// Service locator. Only the shell (composition root) reads from it directly;
/// features receive their dependencies through constructors.
final getIt = GetIt.instance;

/// Registers the running flavor's [config], the device [keyValueStore] and
/// every injectable dependency.
///
/// The injectable environment is the flavor name, so `@dev` registrations
/// (such as the ChaosController) only exist in dev builds. The store is
/// opened by `bootstrap` (it needs async platform setup) and passed in, which
/// also lets tests use an in-memory one.
@InjectableInit(ignoreUnregisteredTypes: [AppConfig, KeyValueStore])
void configureDependencies(
  AppConfig config, {
  required KeyValueStore keyValueStore,
}) {
  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<KeyValueStore>(keyValueStore)
    ..init(environment: config.flavor.name);
}
