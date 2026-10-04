/// Test doubles of `core` for every package's tests. Not used by app code.
library;

import 'package:core/src/telemetry/telemetry.dart';

/// [Telemetry] that remembers everything it was told.
class RecordingTelemetry implements Telemetry {
  final events = <(String, Map<String, Object>)>[];
  final screens = <String>[];
  final errors = <(Object, String?, bool)>[];
  final traces = <RecordedTrace>[];
  final users = <String?>[];

  /// Names of the events, in order.
  List<String> get eventNames => [for (final (name, _) in events) name];

  @override
  void event(String name, [Map<String, Object> parameters = const {}]) =>
      events.add((name, parameters));

  @override
  void screen(String name) => screens.add(name);

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) => errors.add((error, reason, fatal));

  @override
  RecordedTrace startTrace(String name) {
    final trace = RecordedTrace(name);
    traces.add(trace);
    return trace;
  }

  @override
  void setUser(String? id) => users.add(id);
}

class RecordedTrace implements TelemetryTrace {
  RecordedTrace(this.name);

  final String name;
  final attributes = <String, String>{};
  var stopped = false;

  @override
  void setAttribute(String name, String value) => attributes[name] = value;

  @override
  void stop() => stopped = true;
}
