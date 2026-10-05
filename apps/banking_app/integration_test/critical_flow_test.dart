// Critical flow, end to end, against the real Firebase dev project:
// login → Inicio → Cuentas → account → movements (two pages from Firestore)
// → logout.
//
// Run it on a device or emulator with `make e2e`. It signs in with a test
// user of Firebase dev whose credentials come from
// apps/banking_app/e2e.env.json (git-ignored; see e2e.env.example.json).
import 'package:accounts/accounts.dart';
import 'package:banking_app/main_dev.dart' as app;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'login, home, account with all its movements and logout',
    (tester) async {
      if (_email.isEmpty || _password.isEmpty) {
        fail(
          'Missing E2E_EMAIL or E2E_PASSWORD: run `make e2e`, which reads '
          'apps/banking_app/e2e.env.json.',
        );
      }

      final testErrorHandler = FlutterError.onError;
      await app.main();
      // bootstrap sends Flutter errors to Crashlytics; here they must fail
      // the test.
      FlutterError.onError = testErrorHandler;

      await _startSignedOut(tester);

      _step('Login');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        _email,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        _password,
      );
      await _tap(tester, find.widgetWithText(AppButton, 'Iniciar sesión'));

      _step('Inicio: the balance of the two accounts');
      // A new user's first login also opens its accounts.
      await _waitFor(tester, find.textContaining('2 cuentas'));
      expect(find.textContaining('¡Hola'), findsOneWidget);

      _step('Cuentas → Cuenta de Ahorros');
      await _tap(tester, _tab('Cuentas'));
      await _tap(tester, find.text('Cuenta de Ahorros'));
      await _waitFor(tester, find.widgetWithText(AppBar, 'Cuenta de Ahorros'));

      _step('Movements down to the oldest one, on the second page');
      await _scrollUntilFound(tester, find.text('Depósito de apertura'));

      _step('Logout');
      await _tap(tester, _tab('Perfil'));
      await _tap(tester, find.widgetWithText(AppButton, 'Cerrar sesión'));
      await _waitFor(tester, find.text('Bienvenido de nuevo'));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

/// Leaves the app on the login screen, whatever state the device was in:
/// a new install shows the onboarding, and an earlier run that failed may
/// have left a session open.
Future<void> _startSignedOut(WidgetTester tester) async {
  final login = find.text('Bienvenido de nuevo');
  final onboarding = find.text('¿Ya tienes cuenta?');
  final home = find.byType(NavigationBar);
  await _pumpUntil(
    tester,
    () => [login, onboarding, home].any((f) => f.evaluate().isNotEmpty),
    what: 'the login, the onboarding or the home',
  );
  if (onboarding.evaluate().isNotEmpty) {
    _step('Onboarding → Inicia sesión');
    await _tap(tester, find.text('Inicia sesión'));
  } else if (home.evaluate().isNotEmpty) {
    _step('Signing out a session left open');
    await _tap(tester, _tab('Perfil'));
    await _tap(tester, find.widgetWithText(AppButton, 'Cerrar sesión'));
  }
  await _waitFor(tester, login);
}

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Pumps frames until [condition] holds. The app talks to the real
/// Firebase, so no fixed wait is always enough, and loading spinners never
/// let `pumpAndSettle` finish.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String what,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Not found after ${timeout.inSeconds} s: $what');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _waitFor(WidgetTester tester, Finder finder) =>
    _pumpUntil(tester, () => finder.evaluate().isNotEmpty, what: '$finder');

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  // The keyboard or the scroll position may hide it.
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// Scrolls the movements down until [finder] shows up. The list asks
/// Firestore for the next page (20 at a time) when it gets close to the end.
Future<void> _scrollUntilFound(WidgetTester tester, Finder finder) async {
  final list = find
      .descendant(
        of: find.byType(AccountDetailPage),
        matching: find.byType(Scrollable),
      )
      .first;
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Not found after 30 s scrolling the movements: $finder');
    }
    await tester.drag(list, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.ensureVisible(finder);
}

void _step(String name) => debugPrint('E2E · $name');
