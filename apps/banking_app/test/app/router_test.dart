import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

Finder _appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  group('Startup by session', () {
    testWidgets('a fresh install starts with the onboarding', (tester) async {
      await pumpApp(tester);

      expect(find.text('Tu banco en tu bolsillo'), findsOneWidget);
    });

    testWidgets('finishing the onboarding opens the sign-up form', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text('Omitir'));
      await tester.pumpAndSettle();

      expect(find.text('Abre tu cuenta digital'), findsOneWidget);
    });

    testWidgets('a returning signed-out user lands on the login', (
      tester,
    ) async {
      await pumpApp(tester, hasSeenOnboarding: true);

      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    });

    testWidgets('a stored session opens the home shell with four tabs', (
      tester,
    ) async {
      await pumpApp(tester, signedInUser: testUser);

      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(_appBarTitle('Inicio'), findsOneWidget);
    });
  });

  group('Session changes', () {
    testWidgets('signing in navigates to home', (tester) async {
      await pumpApp(tester, hasSeenOnboarding: true);

      await tester.enterText(find.byType(TextField).at(0), 'mateo@nexo.ec');
      await tester.enterText(find.byType(TextField).at(1), 'nexo2026');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('signing out from the profile returns to the login', (
      tester,
    ) async {
      await pumpApp(tester, signedInUser: testUser, hasSeenOnboarding: true);

      await tester.tap(_tab('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Mateo Moreno'), findsOneWidget);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    });

    testWidgets('the accounts tab lists accounts and opens the detail', (
      tester,
    ) async {
      await pumpApp(tester, signedInUser: testUser);

      await tester.tap(_tab('Cuentas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cuenta de Ahorros'));
      await tester.pumpAndSettle();

      expect(_appBarTitle('Cuenta de Ahorros'), findsOneWidget);
      expect(find.text('Supermaxi Mall del Sol'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('tabs switch the visible section', (tester) async {
      await pumpApp(tester, signedInUser: testUser);

      await tester.tap(_tab('Cuentas'));
      await tester.pumpAndSettle();

      expect(_appBarTitle('Cuentas'), findsOneWidget);
      expect(_appBarTitle('Inicio'), findsNothing);
    });
  });

  group('Localization', () {
    testWidgets('uses English on an English device', (tester) async {
      await pumpApp(tester, deviceLocales: const [Locale('en', 'US')]);

      expect(find.text('Your bank in your pocket'), findsOneWidget);
    });

    testWidgets('falls back to Spanish for unsupported languages', (
      tester,
    ) async {
      await pumpApp(tester, deviceLocales: const [Locale('fr', 'FR')]);

      expect(find.text('Tu banco en tu bolsillo'), findsOneWidget);
    });
  });
}
