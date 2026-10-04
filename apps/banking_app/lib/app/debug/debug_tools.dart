import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/notifications.dart';

/// Turns Firestore's network off and on (dev tooling). With it off, the app
/// works from Firestore's offline cache, as without connectivity, and
/// recovers when it is turned back on.
///
/// Firestore has no getter for this state, so the switch remembers it.
class FirestoreNetworkSwitch extends ValueNotifier<bool> {
  FirestoreNetworkSwitch(this._setNetwork) : super(true);

  /// `FirebaseFirestore.enableNetwork` / `disableNetwork` in the app.
  final Future<void> Function({required bool enabled}) _setNetwork;

  Future<void> setEnabled({required bool enabled}) async {
    await _setNetwork(enabled: enabled);
    value = enabled;
  }
}

/// What the debug panel controls. It only exists in the dev flavor: in prod
/// nothing creates it and the panel's route does not exist.
class DebugTools {
  const DebugTools({
    required this.chaos,
    required this.firestoreNetwork,
    required this.push,
    required this.telemetry,
    required this.crash,
  });

  /// Failures injected into HTTP calls (ChaosInterceptor).
  final ChaosController chaos;
  final FirestoreNetworkSwitch firestoreNetwork;

  /// To show this device's token, for test messages from the console.
  final PushService push;

  /// To send a test error to Crashlytics.
  final Telemetry telemetry;

  /// Crashes the app on purpose (Crashlytics' test crash).
  final VoidCallback crash;
}
