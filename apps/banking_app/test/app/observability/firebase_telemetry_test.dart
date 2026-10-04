import 'package:banking_app/app/observability/firebase_telemetry.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

class _MockCrashlytics extends Mock implements FirebaseCrashlytics {}

class _MockPerformance extends Mock implements FirebasePerformance {}

class _MockTrace extends Mock implements Trace {}

void main() {
  late _MockAnalytics analytics;
  late _MockCrashlytics crashlytics;
  late _MockPerformance performance;
  late _MockTrace trace;
  late FirebaseTelemetry telemetry;

  setUp(() {
    analytics = _MockAnalytics();
    crashlytics = _MockCrashlytics();
    performance = _MockPerformance();
    trace = _MockTrace();
    telemetry = FirebaseTelemetry(
      analytics: analytics,
      crashlytics: crashlytics,
      performance: performance,
    );
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => analytics.logScreenView(screenName: any(named: 'screenName')),
    ).thenAnswer((_) async {});
    when(
      () => analytics.setUserId(id: any(named: 'id')),
    ).thenAnswer((_) async {});
    when(
      () => crashlytics.recordError(
        any<Object>(),
        any(),
        reason: any(named: 'reason'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) async {});
    when(() => crashlytics.setUserIdentifier(any())).thenAnswer((_) async {});
    when(() => performance.newTrace(any())).thenReturn(trace);
    when(() => trace.start()).thenAnswer((_) async {});
    when(() => trace.stop()).thenAnswer((_) async {});
  });

  test('events and screens go to Analytics', () {
    telemetry
      ..event('transfer_failed', {'reason': 'network'})
      ..screen('/accounts/:accountId');

    verify(
      () => analytics.logEvent(
        name: 'transfer_failed',
        parameters: {'reason': 'network'},
      ),
    ).called(1);
    verify(
      () => analytics.logScreenView(screenName: '/accounts/:accountId'),
    ).called(1);
  });

  test('errors go to Crashlytics with reason and severity', () {
    final error = StateError('boom');
    final stack = StackTrace.current;

    telemetry.recordError(error, stack, reason: 'sdui', fatal: true);

    verify(
      () => crashlytics.recordError(error, stack, reason: 'sdui', fatal: true),
    ).called(1);
  });

  test('traces go to Performance', () {
    telemetry.startTrace('transfer_submit')
      ..setAttribute('result', 'success')
      ..stop();

    verifyInOrder([
      () => performance.newTrace('transfer_submit'),
      () => trace.start(),
      () => trace.putAttribute('result', 'success'),
      () => trace.stop(),
    ]);
  });

  test('the user is the Firebase uid, and empty after sign-out', () {
    telemetry
      ..setUser('uid-1')
      ..setUser(null);

    verify(() => analytics.setUserId(id: 'uid-1')).called(1);
    verify(() => crashlytics.setUserIdentifier('uid-1')).called(1);
    verify(() => analytics.setUserId()).called(1);
    verify(() => crashlytics.setUserIdentifier('')).called(1);
  });

  test('a failing report never breaks the app', () async {
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) => Future.error(Exception('no network')));

    telemetry.event('login');
    await Future<void>.delayed(Duration.zero);
  });
}
