import 'package:banking_app/app/app.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/di/injection.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Startup shared by every flavor: Firebase with the flavor's options,
/// dependency graph for the flavor, then the app.
Future<void> bootstrap({
  required AppConfig config,
  required FirebaseOptions firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerDesignSystemLicenses();
  await Firebase.initializeApp(options: firebaseOptions);
  configureDependencies(config);
  runApp(App(config: getIt<AppConfig>(), router: getIt<GoRouter>()));
}
