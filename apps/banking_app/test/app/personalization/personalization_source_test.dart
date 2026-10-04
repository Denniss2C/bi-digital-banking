import 'package:banking_app/app/home/default_home_layout.dart';
import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:banking_app/app/personalization/personalization_source.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  late _MockRemoteConfig remoteConfig;
  late RemoteConfigPersonalizationSource source;

  /// Minimum fetch intervals set so far, in order.
  late List<Duration> intervals;

  setUpAll(() {
    registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: Duration.zero,
        minimumFetchInterval: Duration.zero,
      ),
    );
  });

  setUp(() {
    remoteConfig = _MockRemoteConfig();
    source = RemoteConfigPersonalizationSource(
      remoteConfig,
      minimumFetchInterval: const Duration(hours: 1),
    );
    intervals = [];
    when(() => remoteConfig.setConfigSettings(any())).thenAnswer(
      (invocation) async => intervals.add(
        (invocation.positionalArguments.single as RemoteConfigSettings)
            .minimumFetchInterval,
      ),
    );
    when(() => remoteConfig.setDefaults(any())).thenAnswer((_) async {});
    when(() => remoteConfig.ensureInitialized()).thenAnswer((_) async {});
    when(() => remoteConfig.setCustomSignals(any())).thenAnswer((_) async {});
    when(() => remoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
    when(() => remoteConfig.activate()).thenAnswer((_) async => true);
  });

  test(
    'initialize sets the embedded defaults and the fetch interval',
    () async {
      await source.initialize();

      final defaults =
          verify(() => remoteConfig.setDefaults(captureAny())).captured.single
              as Map<String, Object>;
      expect(defaults[PersonalizationKeys.homeLayout], defaultHomeLayout);
      expect(defaults[PersonalizationKeys.transfersEnabled], isTrue);
      expect(defaults[PersonalizationKeys.aiAssistantEnabled], isFalse);
      expect(intervals, [const Duration(hours: 1)]);
      verify(() => remoteConfig.ensureInitialized()).called(1);
      verifyNever(() => remoteConfig.fetchAndActivate());
    },
  );

  test('a segment is a custom signal, fetched without waiting', () async {
    await source.setSegment('saver');

    verifyInOrder([
      () => remoteConfig.setCustomSignals({'segment': 'saver'}),
      () => remoteConfig.setConfigSettings(any()),
      () => remoteConfig.fetchAndActivate(),
      () => remoteConfig.setConfigSettings(any()),
    ]);
    expect(intervals, [Duration.zero, const Duration(hours: 1)]);
  });

  test('unsetting the segment does not fetch', () async {
    await source.setSegment(null);

    verify(() => remoteConfig.setCustomSignals({'segment': null})).called(1);
    verifyNever(() => remoteConfig.fetchAndActivate());
  });

  test('a failed fetch keeps the active values and the interval', () async {
    when(() => remoteConfig.fetchAndActivate()).thenThrow(Exception('offline'));

    await expectLater(source.setSegment('traveler'), completes);
    await expectLater(source.refresh(), completes);

    expect(intervals.last, const Duration(hours: 1));
  });

  test('current reads the layout and the flags', () {
    when(
      () => remoteConfig.getString(PersonalizationKeys.homeLayout),
    ).thenReturn('{"components": []}');
    when(
      () => remoteConfig.getBool(PersonalizationKeys.transfersEnabled),
    ).thenReturn(false);
    when(
      () => remoteConfig.getBool(PersonalizationKeys.fxEnabled),
    ).thenReturn(true);
    when(
      () => remoteConfig.getBool(PersonalizationKeys.aiAssistantEnabled),
    ).thenReturn(true);

    expect(
      source.current,
      const PersonalizationConfig(
        homeLayout: '{"components": []}',
        flags: FeatureFlags(transfers: false, aiAssistant: true),
      ),
    );
  });

  test('a real-time update activates the new values', () async {
    when(() => remoteConfig.onConfigUpdated).thenAnswer(
      (_) => Stream.value(RemoteConfigUpdate({PersonalizationKeys.homeLayout})),
    );
    when(() => remoteConfig.getString(any())).thenReturn('{"components": []}');
    when(() => remoteConfig.getBool(any())).thenReturn(true);

    final update = await source.updates.first;

    verify(() => remoteConfig.activate()).called(1);
    expect(update.homeLayout, '{"components": []}');
  });
}
