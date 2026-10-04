import 'dart:async';
import 'dart:developer' as developer;

import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Where personalization comes from: Remote Config in the app, a fake in
/// tests.
abstract interface class PersonalizationSource {
  /// Sets the embedded defaults and applies the values cached from the last
  /// session. No network.
  Future<void> initialize();

  /// Personalizes for [segment] (a custom signal that Remote Config
  /// conditions match on) and fetches right away, so a new segment applies
  /// without waiting for the cache to expire. `null` unsets it.
  Future<void> setSegment(String? segment);

  /// Fetches and applies the latest values. Never throws: offline, the
  /// active values stay.
  Future<void> refresh();

  PersonalizationConfig get current;

  /// Values published while the app runs (real-time updates).
  Stream<PersonalizationConfig> get updates;
}

/// [PersonalizationSource] on Firebase Remote Config.
class RemoteConfigPersonalizationSource implements PersonalizationSource {
  RemoteConfigPersonalizationSource(
    this._remoteConfig, {
    required this.minimumFetchInterval,
  });

  final FirebaseRemoteConfig _remoteConfig;

  /// Interval restored after a fetch that had to ignore it.
  final Duration minimumFetchInterval;

  RemoteConfigSettings _settings(Duration minimumFetchInterval) =>
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: minimumFetchInterval,
      );

  @override
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(_settings(minimumFetchInterval));
    await _remoteConfig.setDefaults(
      PersonalizationConfig.defaults.toRemoteConfigDefaults(),
    );
    await _remoteConfig.ensureInitialized();
  }

  @override
  Future<void> setSegment(String? segment) async {
    await _remoteConfig.setCustomSignals({
      PersonalizationKeys.segmentSignal: segment,
    });
    if (segment != null) await _fetch(ignoreInterval: true);
  }

  @override
  Future<void> refresh() => _fetch(ignoreInterval: false);

  Future<void> _fetch({required bool ignoreInterval}) async {
    try {
      if (ignoreInterval) {
        await _remoteConfig.setConfigSettings(_settings(Duration.zero));
      }
      await _remoteConfig.fetchAndActivate();
    } on Object catch (error) {
      // Offline or throttled: the values already active stay.
      developer.log('Fetch failed: $error', name: 'personalization');
    } finally {
      if (ignoreInterval) {
        await _remoteConfig.setConfigSettings(_settings(minimumFetchInterval));
      }
    }
  }

  @override
  PersonalizationConfig get current => PersonalizationConfig(
    homeLayout: _remoteConfig.getString(PersonalizationKeys.homeLayout),
    flags: FeatureFlags(
      transfers: _remoteConfig.getBool(PersonalizationKeys.transfersEnabled),
      fx: _remoteConfig.getBool(PersonalizationKeys.fxEnabled),
      aiAssistant: _remoteConfig.getBool(
        PersonalizationKeys.aiAssistantEnabled,
      ),
    ),
  );

  @override
  Stream<PersonalizationConfig> get updates =>
      _remoteConfig.onConfigUpdated.asyncMap((_) async {
        // The SDK already fetched the new values; make them active.
        await _remoteConfig.activate();
        return current;
      });
}
