// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loading => 'Loading';

  @override
  String get tabHome => 'Home';

  @override
  String get tabAccounts => 'Accounts';

  @override
  String get tabFx => 'Currencies';

  @override
  String get tabProfile => 'Profile';

  @override
  String get comingSoonMessage =>
      'This section arrives in the next phases of the project.';

  @override
  String get signOutAction => 'Sign out';

  @override
  String profileSignedInAs(String email) {
    return 'Signed in as $email';
  }
}
