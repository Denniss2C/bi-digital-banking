import 'package:auth/auth.dart';
import 'package:auth/src/presentation/forms/auth_messages.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

void main() {
  group('AuthPage', () {
    late MockAuthRepository repository;

    setUp(() => repository = MockAuthRepository());

    testWidgets('submitting an empty form shows the field errors', (
      tester,
    ) async {
      await tester.pumpLocalized(AuthPage(repository: repository));

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('shows a localized message when the credentials are wrong', (
      tester,
    ) async {
      when(
        () => repository.signIn(email: 'a@b.ec', password: 'wrong'),
      ).thenAnswer(
        (_) async =>
            const Left(AuthFailure(code: AuthErrorCode.invalidCredentials)),
      );
      await tester.pumpLocalized(AuthPage(repository: repository));

      await tester.enterText(find.byType(TextField).at(0), 'a@b.ec');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    });

    testWidgets('the segmented control switches to the sign-up form', (
      tester,
    ) async {
      await tester.pumpLocalized(AuthPage(repository: repository));

      await tester.tap(find.text('Crear cuenta').first);
      await tester.pumpAndSettle();

      expect(find.text('Nombre completo'), findsOneWidget);
      expect(
        find.text('Mínimo 8 caracteres, con letras y números'),
        findsOneWidget,
      );
    });

    testWidgets('the password toggle is labeled for screen readers', (
      tester,
    ) async {
      await tester.pumpLocalized(AuthPage(repository: repository));

      expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });
  });

  group('OnboardingPage', () {
    testWidgets('continue walks the slides and the last one finishes', (
      tester,
    ) async {
      var finished = 0;
      await tester.pumpLocalized(
        OnboardingPage(onFinished: () => finished++, onSignIn: () {}),
      );

      expect(find.text('Tu banco en tu bolsillo'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Seguridad de grado bancario'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comenzar'));
      expect(finished, 1);
    });

    testWidgets('skip and sign in report the choice', (tester) async {
      var finished = 0;
      var signIn = 0;
      await tester.pumpLocalized(
        OnboardingPage(onFinished: () => finished++, onSignIn: () => signIn++),
      );

      await tester.tap(find.text('Omitir'));
      await tester.tap(find.text('Inicia sesión'));

      expect(finished, 1);
      expect(signIn, 1);
    });
  });

  test('failure messages cover network and every auth code', () async {
    final l10n = await AuthLocalizations.delegate.load(const Locale('es'));

    expect(
      failureMessage(l10n, const NetworkFailure()),
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    );
    for (final code in AuthErrorCode.values) {
      expect(failureMessage(l10n, AuthFailure(code: code)), isNotEmpty);
    }
  });
}
