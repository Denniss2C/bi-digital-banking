import 'dart:io';

import 'package:banking_app/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('dev enables debug tools', () {
      expect(AppConfig.dev.flavor, Flavor.dev);
      expect(AppConfig.dev.enableDebugTools, isTrue);
    });

    test('prod never enables debug tools', () {
      expect(AppConfig.prod.flavor, Flavor.prod);
      expect(AppConfig.prod.enableDebugTools, isFalse);
    });

    // Guards against drift between the Dart config and the native flavors.
    test('app names match the native flavor configuration', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final devXcconfig = File('ios/Flutter/dev.xcconfig').readAsStringSync();
      final prodXcconfig = File('ios/Flutter/prod.xcconfig').readAsStringSync();

      expect(
        gradle,
        contains(
          'manifestPlaceholders["appName"] = "${AppConfig.dev.appName}"',
        ),
      );
      expect(
        gradle,
        contains(
          'manifestPlaceholders["appName"] = "${AppConfig.prod.appName}"',
        ),
      );
      expect(
        devXcconfig,
        contains('APP_DISPLAY_NAME = ${AppConfig.dev.appName}'),
      );
      expect(
        prodXcconfig,
        contains('APP_DISPLAY_NAME = ${AppConfig.prod.appName}'),
      );
    });
  });
}
