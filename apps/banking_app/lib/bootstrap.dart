import 'package:banking_app/app/app.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Startup shared by every flavor: initializes Firebase with the flavor's
/// options and runs the app.
Future<void> bootstrap({
  required AppConfig config,
  required FirebaseOptions firebaseOptions,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(App(config: config));
}
