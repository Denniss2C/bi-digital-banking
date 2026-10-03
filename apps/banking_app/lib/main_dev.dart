import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/bootstrap.dart';
import 'package:banking_app/firebase_options_dev.dart';

Future<void> main() => bootstrap(
  config: AppConfig.dev,
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
);
