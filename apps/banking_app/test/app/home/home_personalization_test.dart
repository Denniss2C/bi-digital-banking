import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fakes.dart';

Finder _appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

const _promoOnly = '''
{"components": [
  {"type": "promo_banner", "id": "remote", "props": {"title": "Promo remota"}}
]}
''';

void main() {
  testWidgets('the layout for the customer segment replaces the embedded one', (
    tester,
  ) async {
    final source = FakePersonalizationSource(
      bySegment: {
        'new_user': const PersonalizationConfig(homeLayout: _promoOnly),
      },
    );
    await pumpApp(tester, signedInUser: testUser, personalization: source);

    expect(source.segments, ['new_user']);
    expect(find.text('Promo remota'), findsOneWidget);
    expect(find.text('Operaciones frecuentes'), findsNothing);
  });

  testWidgets('an unusable remote layout falls back to the embedded one', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedInUser: testUser,
      personalization: FakePersonalizationSource(
        current: const PersonalizationConfig(homeLayout: '{oops'),
      ),
    );

    expect(find.text('Operaciones frecuentes'), findsOneWidget);
  });

  testWidgets('publishing in the console changes the home while it runs', (
    tester,
  ) async {
    final source = FakePersonalizationSource();
    await pumpApp(tester, signedInUser: testUser, personalization: source);
    expect(find.text('Operaciones frecuentes'), findsOneWidget);

    source.publish(const PersonalizationConfig(homeLayout: _promoOnly));
    await tester.pumpAndSettle();

    expect(find.text('Promo remota'), findsOneWidget);
    expect(find.text('Operaciones frecuentes'), findsNothing);
  });

  testWidgets('a server action to a screen the app does not have is ignored', (
    tester,
  ) async {
    const layout = '''
      {"components": [{"type": "quick_actions", "props": {"items": [
        {"label": "Sorpresa", "action": {"type": "navigate", "route": "/promo/xyz"}}
      ]}}]}
    ''';
    await pumpApp(
      tester,
      signedInUser: testUser,
      personalization: FakePersonalizationSource(
        current: const PersonalizationConfig(homeLayout: layout),
      ),
    );

    await tester.tap(find.text('Sorpresa'));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Mateo!'), findsOneWidget);
  });

  group('with transfers turned off remotely', () {
    final transfersOff = FakePersonalizationSource(
      current: const PersonalizationConfig(
        flags: FeatureFlags(transfers: false),
      ),
    );

    testWidgets('the home shortcut explains it is not available', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signedInUser: testUser,
        personalization: transfersOff,
      );

      await tester.tap(find.text('Transferir'));
      await tester.pumpAndSettle();

      expect(
        find.text('Esta función no está disponible por ahora.'),
        findsOneWidget,
      );
      expect(_appBarTitle('Transferir dinero'), findsNothing);
    });

    testWidgets('Cuentas has no button and the route sends back', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signedInUser: testUser,
        personalization: transfersOff,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Cuentas'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Transferir'), findsNothing);

      // A deep link (e.g. from a push) cannot open it either.
      GoRouter.of(
        tester.element(find.byType(NavigationBar)),
      ).go('/accounts/transfer');
      await tester.pumpAndSettle();

      expect(_appBarTitle('Transferir dinero'), findsNothing);
      expect(_appBarTitle('Cuentas'), findsOneWidget);
    });
  });

  testWidgets('pull to refresh asks Remote Config for the latest values', (
    tester,
  ) async {
    final source = FakePersonalizationSource();
    await pumpApp(tester, signedInUser: testUser, personalization: source);

    await tester.fling(find.text('¡Hola, Mateo!'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(source.refreshes, 1);
  });
}
