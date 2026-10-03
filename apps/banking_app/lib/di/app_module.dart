import 'package:banking_app/app/router/app_router.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

/// Objects the shell owns that cannot be annotated directly.
@module
abstract class AppModule {
  @lazySingleton
  GoRouter get router => createRouter();

  /// Debug tooling: registered only in the dev environment (dev flavor).
  @dev
  @lazySingleton
  ChaosController get chaosController => ChaosController();
}
