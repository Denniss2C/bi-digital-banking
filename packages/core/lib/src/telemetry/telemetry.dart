/// What the app reports to production monitoring. The shell implements it
/// with Firebase (Analytics, Crashlytics and Performance); features only see
/// this interface.
///
/// Never send personal data: no names, emails, account numbers or amounts.
/// The user is identified only by the pseudonymous Firebase uid.
abstract interface class Telemetry {
  /// A business or UX event (Analytics), e.g. `transfer_completed`.
  void event(String name, [Map<String, Object> parameters = const {}]);

  /// A screen the user opened, by route pattern (`/accounts/:accountId`).
  void screen(String name);

  /// An unexpected error worth investigating (Crashlytics). Expected
  /// conditions, such as being offline, are events, not errors.
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Starts measuring [name] (Performance) until [TelemetryTrace.stop].
  TelemetryTrace startTrace(String name);

  /// The signed-in user (Firebase uid), or `null` after sign-out.
  void setUser(String? id);
}

/// A running Performance trace.
abstract interface class TelemetryTrace {
  void setAttribute(String name, String value);
  void stop();
}

/// Telemetry that reports nothing (default for features and tests).
class NoopTelemetry implements Telemetry {
  const NoopTelemetry();

  @override
  void event(String name, [Map<String, Object> parameters = const {}]) {}

  @override
  void screen(String name) {}

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {}

  @override
  TelemetryTrace startTrace(String name) => const _NoopTrace();

  @override
  void setUser(String? id) {}
}

class _NoopTrace implements TelemetryTrace {
  const _NoopTrace();

  @override
  void setAttribute(String name, String value) {}

  @override
  void stop() {}
}
