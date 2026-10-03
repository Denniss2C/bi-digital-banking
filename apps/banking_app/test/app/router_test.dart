import 'package:banking_app/app/app.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  List<Locale> deviceLocales = const [Locale('es', 'EC')],
}) async {
  tester.platformDispatcher.localesTestValue = deviceLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(App(config: AppConfig.prod, router: createRouter()));
  await tester.pumpAndSettle();
}

Finder _appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

void main() {
  group('Router', () {
    testWidgets('starts at the splash and continues to the login', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(_appBarTitle('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('continue opens the home shell with four tabs', (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(_appBarTitle('Inicio'), findsOneWidget);
    });

    testWidgets('tabs switch the visible section', (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Cuentas'),
        ),
      );
      await tester.pumpAndSettle();

      expect(_appBarTitle('Cuentas'), findsOneWidget);
      expect(_appBarTitle('Inicio'), findsNothing);
    });
  });

  group('Localization', () {
    testWidgets('uses English on an English device', (tester) async {
      await _pumpApp(tester, deviceLocales: const [Locale('en', 'US')]);

      expect(_appBarTitle('Sign in'), findsOneWidget);
    });

    testWidgets('falls back to Spanish for unsupported languages', (
      tester,
    ) async {
      await _pumpApp(tester, deviceLocales: const [Locale('fr', 'FR')]);

      expect(_appBarTitle('Iniciar sesión'), findsOneWidget);
    });
  });
}
