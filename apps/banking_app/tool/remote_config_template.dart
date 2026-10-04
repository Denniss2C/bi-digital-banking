// Builds firebase/remoteconfig.template.json from the home layouts in
// firebase/remote-config/. Run it with `make rc-template` (or from
// apps/banking_app: `dart run tool/remote_config_template.dart`) and publish
// the result with `make deploy-rc`.
import 'dart:convert';
import 'dart:io';

/// Segments with their own home layout (`home_layout.<segment>.json`) and the
/// color of their condition in the console. Any other segment, `new_user`
/// included, gets the default layout.
const segmentColors = {'saver': 'GREEN', 'traveler': 'BLUE'};

/// Remote Config template (REST API format) for the given layouts.
///
/// One condition per segment matches the `segment` custom signal the app
/// sends. Flag defaults must match `FeatureFlags` in the app; a test checks.
Map<String, Object?> buildRemoteConfigTemplate({
  required String defaultLayout,
  required Map<String, String> segmentLayouts,
}) {
  // Values are stored compact; the files in firebase/remote-config are the
  // readable version.
  String compact(String json) => jsonEncode(jsonDecode(json));

  Map<String, Object?> flag(String description, {required bool enabled}) => {
    'defaultValue': {'value': '$enabled'},
    'description': description,
    'valueType': 'BOOLEAN',
  };

  return {
    'conditions': [
      for (final segment in segmentLayouts.keys)
        {
          'name': 'segment_$segment',
          'expression':
              "app.customSignal['segment'].exactlyMatches(['$segment'])",
          'tagColor': segmentColors[segment] ?? 'INDIGO',
        },
    ],
    'parameters': {
      'home_layout': {
        'defaultValue': {'value': compact(defaultLayout)},
        'conditionalValues': {
          for (final MapEntry(key: segment, value: layout)
              in segmentLayouts.entries)
            'segment_$segment': {'value': compact(layout)},
        },
        'description':
            'Home SDUI layout (contract in packages/sdui/README.md), per '
            'customer segment.',
        'valueType': 'JSON',
      },
      'feature_transfers_enabled': flag(
        'Transfers between own accounts.',
        enabled: true,
      ),
      'feature_fx_enabled': flag('Currency exchange (Divisas).', enabled: true),
      'feature_ai_assistant_enabled': flag(
        'AI financial assistant (bonus).',
        enabled: false,
      ),
    },
  };
}

/// Reads the layouts from [firebaseDir] (relative to apps/banking_app).
Map<String, Object?> buildFromFiles({String firebaseDir = '../../firebase'}) {
  String read(String name) => File(
    '$firebaseDir/remote-config/home_layout.$name.json',
  ).readAsStringSync();
  return buildRemoteConfigTemplate(
    defaultLayout: read('default'),
    segmentLayouts: {
      for (final segment in segmentColors.keys) segment: read(segment),
    },
  );
}

void main() {
  const firebaseDir = '../../firebase';
  final template = buildFromFiles(firebaseDir: firebaseDir);
  File('$firebaseDir/remoteconfig.template.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(template)}\n',
  );
  stdout.writeln('Wrote $firebaseDir/remoteconfig.template.json');
}
