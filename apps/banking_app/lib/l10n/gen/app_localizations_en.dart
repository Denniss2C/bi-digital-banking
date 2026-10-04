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
  String get signOutAction => 'Sign out';

  @override
  String profileSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String homeGreeting(String name) {
    return 'Hi, $name!';
  }

  @override
  String get homeGreetingNoName => 'Hi!';

  @override
  String get featureUnavailable => 'This feature is not available right now.';

  @override
  String get debugEntry => 'Debug panel';

  @override
  String get debugEntryHint => 'Dev only: chaos mode, network and segments';

  @override
  String get debugHttpTitle => 'HTTP network (chaos mode)';

  @override
  String get debugHttpHint =>
      'Affects the app\'s HTTP calls, such as Exchange. Injected failures go through the retries.';

  @override
  String get debugChaosEnabled => 'Enable chaos mode';

  @override
  String debugLatency(int ms) {
    return 'Latency: $ms ms';
  }

  @override
  String debugFailureRate(int percent) {
    return 'Failures: $percent%';
  }

  @override
  String get debugHttpOffline => 'No network (HTTP)';

  @override
  String get debugFirestoreHint =>
      'Offline, the app works from its offline cache: accounts show the notice and transfers explain they need internet.';

  @override
  String get debugFirestoreOnline => 'Firestore connected';

  @override
  String get debugSegmentTitle => 'Customer segment';

  @override
  String get debugSegmentHint =>
      'Changes the segment stored in Firestore: Remote Config sends that segment\'s home live.';

  @override
  String get debugRemoteConfigTitle => 'Remote Config';

  @override
  String get debugFetchNow => 'Fetch values now';

  @override
  String get debugOn => 'On';

  @override
  String get debugOff => 'Off';

  @override
  String get pushOpen => 'Open';

  @override
  String get debugPushTitle => 'Push notifications';

  @override
  String get debugPushHint =>
      'Copy the token and paste it in the Firebase console: Messaging → Send test message. With the custom data route (for example, /fx), tapping the notification opens that screen.';

  @override
  String get debugPushNoToken =>
      'No token yet: sign in and accept the permission.';

  @override
  String get debugCopy => 'Copy token';

  @override
  String get debugCopied => 'Token copied';

  @override
  String get debugObservabilityTitle => 'Observability';

  @override
  String get debugObservabilityHint =>
      'Errors reach the dev project\'s Crashlytics within minutes. The forced crash shows up after reopening the app.';

  @override
  String get debugSendError => 'Send a test error';

  @override
  String get debugErrorSent => 'Error sent to Crashlytics';

  @override
  String get debugCrash => 'Force an app crash';
}
