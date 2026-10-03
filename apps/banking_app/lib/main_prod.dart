import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/bootstrap.dart';
import 'package:banking_app/firebase_options_prod.dart';

Future<void> main() => bootstrap(
  config: AppConfig.prod,
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
);
