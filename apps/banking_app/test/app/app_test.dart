import 'package:banking_app/app/app.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('dev shows the DEV ribbon and the dev app name', (
      tester,
    ) async {
      await tester.pumpWidget(
        App(config: AppConfig.dev, router: createRouter()),
      );
      await tester.pumpAndSettle();

      final banner = tester.widget<Banner>(find.byType(Banner));
      expect(banner.message, 'DEV');
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        AppConfig.dev.appName,
      );
    });

    testWidgets('prod shows no ribbon', (tester) async {
      await tester.pumpWidget(
        App(config: AppConfig.prod, router: createRouter()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Banner), findsNothing);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        AppConfig.prod.appName,
      );
    });
  });
}
