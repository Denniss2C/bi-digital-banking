import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fx_rates/fx_rates.dart';

import '../helpers.dart';

void main() {
  Future<void> pump(WidgetTester tester, FakeFxRatesRepository repository) =>
      tester.pumpLocalized(
        FxPage(
          repository: repository,
          now: () => DateTime.utc(2026, 10, 4, 15),
        ),
      );

  testWidgets('converts 100 USD to euros with the real rate', (tester) async {
    await pump(tester, FakeFxRatesRepository([Right(snapshot())]));

    expect(find.text('88.88 EUR'), findsOneWidget);
    expect(find.text('1 USD = 0.8888 EUR'), findsWidgets);
    expect(find.text('Tasas al día'), findsOneWidget);
  });

  testWidgets('typing an amount and swapping the direction', (tester) async {
    await pump(tester, FakeFxRatesRepository([Right(snapshot())]));

    await tester.enterText(find.byType(TextField), '88.88');
    await tester.tap(find.byTooltip('Invertir la conversión'));
    await tester.pumpAndSettle();

    expect(find.text('100.00 USD'), findsOneWidget);
  });

  testWidgets('choosing another currency', (tester) async {
    await pump(tester, FakeFxRatesRepository([Right(snapshot())]));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('COP · Peso colombiano').last);
    await tester.pumpAndSettle();

    expect(find.text('331,164.43 COP'), findsOneWidget);
  });

  testWidgets('an invalid amount says so instead of converting', (
    tester,
  ) async {
    await pump(tester, FakeFxRatesRepository([Right(snapshot())]));

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un monto válido'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('offline it shows the saved rates with a notice', (tester) async {
    await pump(
      tester,
      FakeFxRatesRepository([
        Right(
          snapshot(
            source: FxSource.cache,
            refreshFailure: const NetworkFailure(),
          ),
        ),
      ]),
    );

    expect(find.byType(AppOfflineBanner), findsOneWidget);
    expect(
      find.text('Sin conexión · mostrando las últimas tasas guardadas'),
      findsOneWidget,
    );
    expect(find.text('88.88 EUR'), findsOneWidget);
  });

  testWidgets('without any rates it offers a retry', (tester) async {
    await pump(tester, FakeFxRatesRepository([const Left(NetworkFailure())]));

    expect(find.text('No pudimos cargar las tasas'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('shows when the rates were published and the attribution', (
    tester,
  ) async {
    await pump(tester, FakeFxRatesRepository([Right(snapshot())]));
    await tester.scrollUntilVisible(
      find.textContaining('Rates By Exchange Rate API'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Actualizado hace 14 horas'), findsOneWidget);
    expect(
      find.text(
        'Tasa media de mercado: no es una cotización de compra o venta.',
      ),
      findsOneWidget,
    );
  });
}
