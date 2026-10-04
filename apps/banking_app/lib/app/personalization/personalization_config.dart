import 'package:banking_app/app/home/default_home_layout.dart';
import 'package:equatable/equatable.dart';

/// Remote Config keys (see `firebase/remoteconfig.template.json`).
abstract final class PersonalizationKeys {
  static const homeLayout = 'home_layout';
  static const transfersEnabled = 'feature_transfers_enabled';
  static const fxEnabled = 'feature_fx_enabled';
  static const aiAssistantEnabled = 'feature_ai_assistant_enabled';

  /// Custom signal that Remote Config conditions match on.
  static const segmentSignal = 'segment';
}

/// Features that can be turned off remotely, without a release.
final class FeatureFlags extends Equatable {
  const FeatureFlags({
    this.transfers = true,
    this.fx = true,
    this.aiAssistant = false,
  });

  final bool transfers;

  /// Applied by the fx_rates step (Divisas tab and `fx_widget`).
  final bool fx;

  /// Bonus feature; defined so the flag exists from day one.
  final bool aiAssistant;

  @override
  List<Object?> get props => [transfers, fx, aiAssistant];
}

/// What the server personalizes: the home layout (SDUI JSON) and the flags.
final class PersonalizationConfig extends Equatable {
  const PersonalizationConfig({
    this.homeLayout = defaultHomeLayout,
    this.flags = const FeatureFlags(),
  });

  /// Values embedded in the app: used before Remote Config answers and
  /// whenever it cannot.
  static const defaults = PersonalizationConfig();

  final String homeLayout;
  final FeatureFlags flags;

  /// The same values as Remote Config in-app defaults.
  Map<String, Object> toRemoteConfigDefaults() => {
    PersonalizationKeys.homeLayout: homeLayout,
    PersonalizationKeys.transfersEnabled: flags.transfers,
    PersonalizationKeys.fxEnabled: flags.fx,
    PersonalizationKeys.aiAssistantEnabled: flags.aiAssistant,
  };

  @override
  List<Object?> get props => [homeLayout, flags];
}
