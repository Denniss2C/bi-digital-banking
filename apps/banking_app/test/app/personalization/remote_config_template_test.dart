import 'dart:convert';
import 'dart:io';

import 'package:banking_app/app/home/default_home_layout.dart';
import 'package:banking_app/app/home/home_registry.dart';
import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

import '../../../tool/remote_config_template.dart';
import '../../helpers/fakes.dart';

/// Types whose feature is not built yet (they are skipped meanwhile).
const _pendingTypes = {'fx_widget'};

void main() {
  const firebaseDir = '../../firebase';
  final layoutFiles = Directory('$firebaseDir/remote-config')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList();
  final committed =
      jsonDecode(
            File('$firebaseDir/remoteconfig.template.json').readAsStringSync(),
          )
          as Map<String, Object?>;
  final parameters = committed['parameters']! as Map<String, Object?>;

  test('the committed template is up to date (make rc-template)', () {
    expect(committed, buildFromFiles(firebaseDir: firebaseDir));
  });

  test('the default layout is the one embedded in the app', () {
    final file = File('$firebaseDir/remote-config/home_layout.default.json');
    expect(jsonDecode(file.readAsStringSync()), jsonDecode(defaultHomeLayout));
  });

  test('every layout is valid, renderable and opens only app screens', () {
    final registry = createHomeRegistry(
      accountsRepository: FakeAccountsRepository(),
      userId: 'uid-1',
    );
    expect(layoutFiles, hasLength(1 + segmentColors.length));
    for (final file in layoutFiles) {
      final source = file.readAsStringSync();
      final layout = parseSduiLayout(
        source,
      ).getOrElse((error) => fail('${file.path}: ${error.message}'));
      expect(layout.issues, isEmpty, reason: file.path);
      final unknown = {
        for (final node in layout.components)
          if (!registry.supports(node.type)) node.type,
      };
      expect(_pendingTypes.containsAll(unknown), isTrue, reason: file.path);
      for (final match in RegExp(r'"route": "([^"]+)"').allMatches(source)) {
        expect(
          AppRoutes.isAppLocation(match.group(1)!),
          isTrue,
          reason: '${file.path}: ${match.group(1)}',
        );
      }
    }
  });

  test('flag defaults match the app defaults', () {
    String defaultOf(String key) =>
        ((parameters[key]! as Map)['defaultValue']! as Map)['value']! as String;
    const flags = FeatureFlags();

    expect(
      defaultOf(PersonalizationKeys.transfersEnabled),
      '${flags.transfers}',
    );
    expect(defaultOf(PersonalizationKeys.fxEnabled), '${flags.fx}');
    expect(
      defaultOf(PersonalizationKeys.aiAssistantEnabled),
      '${flags.aiAssistant}',
    );
  });

  test('conditions match on the segment custom signal', () {
    final conditions = (committed['conditions']! as List).cast<Map>();
    expect(conditions.map((condition) => condition['expression']), [
      for (final segment in segmentColors.keys)
        "app.customSignal['${PersonalizationKeys.segmentSignal}']"
            ".exactlyMatches(['$segment'])",
    ]);
  });
}
