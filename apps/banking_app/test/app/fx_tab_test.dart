import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder _appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

void main() {
  testWidgets('the Divisas tab is the converter with real rates', (
    tester,
  ) async {
    await pumpApp(tester, signedInUser: testUser);

    await tester.tap(_tab('Divisas'));
    await tester.pumpAndSettle();

    expect(_appBarTitle('Divisas'), findsOneWidget);
    expect(find.text('Cotizador'), findsOneWidget);
    expect(find.text('88.88 EUR'), findsOneWidget);
  });

  testWidgets('the market card on the home opens Divisas', (tester) async {
    await pumpApp(tester, signedInUser: testUser);
    final card = find.text('Mercado de divisas');
    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();

    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Cotizador'), findsOneWidget);
  });

  group('with Divisas turned off remotely', () {
    final fxOff = FakePersonalizationSource(
      current: const PersonalizationConfig(flags: FeatureFlags(fx: false)),
    );

    testWidgets('the tab explains it is not available', (tester) async {
      await pumpApp(tester, signedInUser: testUser, personalization: fxOff);

      await tester.tap(_tab('Divisas'));
      await tester.pumpAndSettle();

      expect(
        find.text('Esta función no está disponible por ahora.'),
        findsOneWidget,
      );
      expect(find.text('Cotizador'), findsNothing);
    });

    testWidgets('the home skips the market card', (tester) async {
      await pumpApp(tester, signedInUser: testUser, personalization: fxOff);

      expect(
        find.text('Mercado de divisas', skipOffstage: false),
        findsNothing,
      );
      expect(find.text('Operaciones frecuentes'), findsOneWidget);
    });
  });
}
