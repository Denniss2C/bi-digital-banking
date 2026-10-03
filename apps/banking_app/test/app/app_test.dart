import 'package:banking_app/app/app.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('dev shows the DEV ribbon and the dev app name', (
      tester,
    ) async {
      await tester.pumpWidget(const App(config: AppConfig.dev));

      final banner = tester.widget<Banner>(find.byType(Banner));
      expect(banner.message, 'DEV');
      expect(find.text(AppConfig.dev.appName), findsOneWidget);
    });

    testWidgets('prod shows no ribbon', (tester) async {
      await tester.pumpWidget(const App(config: AppConfig.prod));

      expect(find.byType(Banner), findsNothing);
      expect(find.text(AppConfig.prod.appName), findsOneWidget);
    });
  });
}
