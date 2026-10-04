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
      expect(find.text('¡Hola, Mateo!'), findsOneWidget);
    });
  });

  group('Home (server-driven layout)', () {
    testWidgets('shows the balance, shortcuts, promo and movements', (
      tester,
    ) async {
      await pumpApp(tester, signedInUser: testUser);

      expect(find.text(r'$5,095.50'), findsOneWidget);
      expect(find.text('Operaciones frecuentes'), findsOneWidget);
      expect(find.text('NEXO AHORRO FLEXIBLE'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Supermaxi Mall del Sol'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Movimientos recientes'), findsOneWidget);
    });

    testWidgets('a shortcut opens its screen', (tester) async {
      await pumpApp(tester, signedInUser: testUser);

      await tester.tap(find.text('Transferir'));
      await tester.pumpAndSettle();

      expect(_appBarTitle('Transferir dinero'), findsOneWidget);
    });

    testWidgets('the balance card opens the accounts tab', (tester) async {
      await pumpApp(tester, signedInUser: testUser);

      await tester.tap(find.text(r'$5,095.50'));
      await tester.pumpAndSettle();

      expect(_appBarTitle('Cuentas'), findsOneWidget);
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

    testWidgets('a transfer from the accounts tab returns to the list', (
      tester,
    ) async {
      final accounts = FakeAccountsRepository();
      await pumpApp(
        tester,
        signedInUser: testUser,
        accountsRepository: accounts,
      );

      await tester.tap(_tab('Cuentas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferir'));
      await tester.pumpAndSettle();
      expect(_appBarTitle('Transferir dinero'), findsOneWidget);

      await tester.tap(find.text(r'$50.00'));
      await tester.pumpAndSettle();
      final send = find.widgetWithText(FilledButton, 'Transferir');
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.text('Transferencia exitosa'), findsOneWidget);
      expect(accounts.transfers.single.amountCents, 5000);

      await tester.tap(find.text('Ver mis cuentas'));
      await tester.pumpAndSettle();
      expect(_appBarTitle('Cuentas'), findsOneWidget);
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
