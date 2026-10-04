import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fx_rates/fx_rates.dart';
import 'package:sdui/sdui.dart';

import '../helpers.dart';

void main() {
  Future<List<SduiAction>> pump(
    WidgetTester tester,
    FakeFxRatesRepository repository,
    Map<String, Object?> props,
  ) async {
    final actions = <SduiAction>[];
    await tester.pumpLocalized(
      Scaffold(
        body: SduiView(
          layout: SduiLayout(
            components: [
              SduiNode(type: 'fx_widget', properties: SduiProps(props)),
            ],
          ),
          registry: SduiRegistry(
            fxSduiComponents(
              repository: repository,
              now: () => DateTime.utc(2026, 10, 4, 15),
            ),
          ),
          onAction: actions.add,
        ),
      ),
    );
    return actions;
  }

  testWidgets('shows the requested currencies and opens its action', (
    tester,
  ) async {
    final actions = await pump(
      tester,
      FakeFxRatesRepository([Right(snapshot())]),
      {
        'currencies': ['EUR', 'PEN', 'XXX'],
        'action': {'type': 'navigate', 'route': '/fx'},
      },
    );

    expect(find.text('Mercado de divisas'), findsOneWidget);
    expect(find.text('1 USD = 0.8888 EUR'), findsOneWidget);
    expect(find.text('1 USD = 3.4433 PEN'), findsOneWidget);
    // Unknown currencies are skipped.
    expect(find.textContaining('XXX'), findsNothing);
    expect(find.text('Actualizado hace 14 horas'), findsOneWidget);

    await tester.tap(find.text('Mercado de divisas'));
    expect(actions, [const SduiNavigateAction('/fx')]);
  });

  testWidgets('without currencies it shows EUR, COP and PEN', (tester) async {
    await pump(tester, FakeFxRatesRepository([Right(snapshot())]), {});

    expect(find.text('1 USD = 0.8888 EUR'), findsOneWidget);
    expect(find.text('1 USD = 3,311.64 COP'), findsOneWidget);
    expect(find.text('1 USD = 3.4433 PEN'), findsOneWidget);
  });

  testWidgets('offline it says the rates are saved ones', (tester) async {
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
      {},
    );

    expect(
      find.text('Sin conexión · mostrando las últimas tasas guardadas'),
      findsOneWidget,
    );
  });
}
