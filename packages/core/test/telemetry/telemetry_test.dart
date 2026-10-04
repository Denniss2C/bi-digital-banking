import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NoopTelemetry accepts everything and reports nothing', () {
    const telemetry = NoopTelemetry();

    telemetry
      ..event('any', {'a': 1})
      ..screen('/home')
      ..recordError(Exception('x'), StackTrace.current)
      ..setUser('uid')
      ..startTrace('trace').stop();
  });

  test('RecordingTelemetry keeps what it was told, in order', () {
    final telemetry = RecordingTelemetry()
      ..event('login')
      ..event('transfer_failed', {'reason': 'insufficientFunds'})
      ..screen('/accounts')
      ..recordError(StateError('boom'), null, reason: 'sdui', fatal: true)
      ..setUser('uid-1');
    final trace = telemetry.startTrace('transfer_submit')
      ..setAttribute('result', 'success')
      ..stop();

    expect(telemetry.eventNames, ['login', 'transfer_failed']);
    expect(telemetry.events.last.$2, {'reason': 'insufficientFunds'});
    expect(telemetry.screens, ['/accounts']);
    expect(telemetry.errors.single.$2, 'sdui');
    expect(telemetry.errors.single.$3, isTrue);
    expect(telemetry.users, ['uid-1']);
    expect(trace.stopped, isTrue);
    expect(trace.attributes, {'result': 'success'});
  });
}
