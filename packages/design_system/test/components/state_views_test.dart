import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppErrorView', () {
    testWidgets('shows the error and calls onRetry', (tester) async {
      var retries = 0;
      await tester.pumpWithTheme(
        AppErrorView(
          title: 'No pudimos cargar tus cuentas',
          message: 'Revisa tu conexión e inténtalo de nuevo.',
          retryLabel: 'Reintentar',
          onRetry: () => retries++,
        ),
      );

      expect(find.text('No pudimos cargar tus cuentas'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));

      expect(retries, 1);
    });

    testWidgets('fits a small screen at 200% text scale', (tester) async {
      await tester.pumpWithTheme(
        AppErrorView(
          title: 'No pudimos cargar tus cuentas',
          message: 'Revisa tu conexión e inténtalo de nuevo en unos segundos.',
          retryLabel: 'Reintentar',
          onRetry: () {},
        ),
        textScale: 2,
        surfaceSize: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('AppEmptyView', () {
    testWidgets('shows the optional action', (tester) async {
      var actions = 0;
      await tester.pumpWithTheme(
        AppEmptyView(
          title: 'Aún no tienes movimientos',
          actionLabel: 'Ingresar dinero',
          onAction: () => actions++,
        ),
      );

      await tester.tap(find.text('Ingresar dinero'));

      expect(actions, 1);
    });

    testWidgets('renders without an action', (tester) async {
      await tester.pumpWithTheme(
        const AppEmptyView(title: 'Aún no tienes movimientos'),
      );

      expect(find.byType(AppButton), findsNothing);
    });
  });

  group('AppLoading', () {
    testWidgets('announces its semantics label', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWithTheme(
        const AppLoading(
          semanticsLabel: 'Cargando cuentas',
          message: 'Un momento…',
        ),
      );

      expect(find.bySemanticsLabel('Cargando cuentas'), findsOneWidget);
      expect(find.text('Un momento…'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('AppCard', () {
    testWidgets('is tappable and exposed as a button', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWithTheme(
        AppCard(
          onTap: () => taps++,
          semanticsLabel: 'Cuenta de ahorros, saldo 3845 dólares',
          child: const Text('Ahorros'),
        ),
      );

      await tester.tap(find.byType(AppCard));

      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(AppCard)),
        matchesSemantics(
          label: 'Cuenta de ahorros, saldo 3845 dólares',
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('hero variant paints navy with light content', (tester) async {
      await tester.pumpWithTheme(
        const AppCard(variant: AppCardVariant.hero, child: Text('Saldo')),
      );

      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(AppCard),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, AppColors.navy);
      expect(
        DefaultTextStyle.of(tester.element(find.text('Saldo'))).style.color,
        Colors.white,
      );
    });
  });
}
