import 'dart:async';
import 'dart:developer' as developer;

import 'package:core/core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// [Telemetry] on Firebase: events and screens in Analytics, errors in
/// Crashlytics, traces in Performance.
///
/// Reporting must never break the app: every call is fire-and-forget and
/// its own failures are only logged.
class FirebaseTelemetry implements Telemetry {
  FirebaseTelemetry({
    required this.analytics,
    required this.crashlytics,
    required this.performance,
  });

  final FirebaseAnalytics analytics;
  final FirebaseCrashlytics crashlytics;
  final FirebasePerformance performance;

  @override
  void event(String name, [Map<String, Object> parameters = const {}]) =>
      _send(analytics.logEvent(name: name, parameters: parameters));

  @override
  void screen(String name) => _send(analytics.logScreenView(screenName: name));

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) => _send(
    crashlytics.recordError(error, stackTrace, reason: reason, fatal: fatal),
  );

  @override
  TelemetryTrace startTrace(String name) {
    final trace = performance.newTrace(name);
    _send(trace.start());
    return _FirebaseTrace(trace);
  }

  @override
  void setUser(String? id) {
    _send(analytics.setUserId(id: id));
    _send(crashlytics.setUserIdentifier(id ?? ''));
  }
}

class _FirebaseTrace implements TelemetryTrace {
  _FirebaseTrace(this._trace);

  final Trace _trace;

  @override
  void setAttribute(String name, String value) =>
      _trace.putAttribute(name, value);

  @override
  void stop() => _send(_trace.stop());
}

void _send(Future<void> report) => unawaited(
  report.catchError(
    (Object error) => developer.log('Not reported: $error', name: 'telemetry'),
  ),
);
