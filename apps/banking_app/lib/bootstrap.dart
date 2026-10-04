import 'dart:async';

import 'package:auth/auth.dart';
import 'package:banking_app/app/app.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/observability/app_observability.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/app/push/push_coordinator.dart';
import 'package:banking_app/app/session_effects.dart';
import 'package:banking_app/di/injection.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Startup shared by every flavor: Firebase with the flavor's options, the
/// device store, the dependency graph for the flavor, then the app.
Future<void> bootstrap({
  required AppConfig config,
  required FirebaseOptions firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerDesignSystemLicenses();
  await Firebase.initializeApp(options: firebaseOptions);
  final keyValueStore = await HiveKeyValueStore.open();
  configureDependencies(config, keyValueStore: keyValueStore);
  // Every uncaught error reaches Crashlytics: Flutter's (build, layout,
  // gestures) and the rest (async code, platform channels).
  final telemetry = getIt<Telemetry>();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    telemetry.recordError(
      details.exception,
      details.stack,
      reason: details.context?.toString(),
      fatal: true,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    telemetry.recordError(error, stackTrace, fatal: true);
    return true;
  };
  // Lazy singletons: resolving it starts listening to the session.
  getIt<SessionEffects>();
  getIt<AppObservability>().start();
  final push = getIt<PushCoordinator>();
  unawaited(push.start());
  runApp(
    App(
      config: getIt<AppConfig>(),
      router: getIt<GoRouter>(),
      session: getIt<SessionCubit>(),
      // Resolving it starts loading the personalization for the session.
      personalization: getIt<PersonalizationCubit>(),
      push: push,
    ),
  );
}
