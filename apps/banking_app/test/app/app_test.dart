import 'package:banking_app/app/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  group('App', () {
    testWidgets('dev shows the DEV ribbon and the dev app name', (
      tester,
    ) async {
      await pumpApp(tester, config: AppConfig.dev);

      expect(tester.widget<Banner>(find.byType(Banner)).message, 'DEV');
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        AppConfig.dev.appName,
      );
    });

    testWidgets('prod shows no ribbon', (tester) async {
      await pumpApp(tester);

      expect(find.byType(Banner), findsNothing);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        AppConfig.prod.appName,
      );
    });
  });
}
