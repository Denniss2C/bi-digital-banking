import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

import '../helpers.dart';

void main() {
  const shortcuts = {
    'title': 'Operaciones frecuentes',
    'items': [
      {
        'label': 'Transferir',
        'icon': 'send',
        'highlighted': true,
        'action': {'type': 'navigate', 'route': '/accounts/transfer'},
      },
      {
        'label': 'Divisas',
        'icon': 'fx',
        'action': {'type': 'navigate', 'route': '/fx'},
      },
      {
        'label': 'Cajero',
        'icon': 'atm',
        'action': {'type': 'open_map'},
      },
      {
        'icon': 'qr',
        'action': {'type': 'navigate', 'route': '/qr'},
      },
      {
        'label': 'Cuentas',
        'icon': 'accounts',
        'action': {'type': 'navigate', 'route': '/accounts'},
      },
    ],
  };

  Future<List<SduiAction>> pump(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    final actions = <SduiAction>[];
    await tester.pumpSdui(
      SduiView(
        layout: SduiLayout(
          components: [
            SduiNode(type: 'quick_actions', properties: SduiProps(shortcuts)),
          ],
        ),
        registry: SduiRegistry(standardSduiComponents),
        onAction: actions.add,
      ),
      textScale: textScale,
    );
    return actions;
  }

  testWidgets('shows the valid shortcuts and runs their actions', (
    tester,
  ) async {
    final actions = await pump(tester);

    expect(find.text('Operaciones frecuentes'), findsOneWidget);
    expect(find.text('Transferir'), findsOneWidget);
    expect(find.text('Divisas'), findsOneWidget);
    expect(find.text('Cuentas'), findsOneWidget);
    // Unsupported action and missing label.
    expect(find.text('Cajero'), findsNothing);
    expect(find.byIcon(Icons.qr_code_2), findsNothing);

    await tester.tap(find.text('Divisas'));
    expect(actions, [const SduiNavigateAction('/fx')]);
  });

  testWidgets('each shortcut reads as a button with its label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.text('Transferir')),
      isSemantics(label: 'Transferir', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('four per row, as in the design', (tester) async {
    await pump(tester);

    final first = tester.getTopLeft(find.text('Transferir')).dy;
    expect(tester.getTopLeft(find.text('Cuentas')).dy, first);
  });

  testWidgets('with large text, two per row so labels are not cut', (
    tester,
  ) async {
    await pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    final first = tester.getTopLeft(find.text('Transferir')).dy;
    expect(tester.getTopLeft(find.text('Divisas')).dy, first);
    expect(tester.getTopLeft(find.text('Cuentas')).dy, greaterThan(first));
  });

  test('without a valid shortcut the component is skipped', () {
    expect(
      () => QuickActions.fromProps(
        SduiProps(const {
          'items': [
            {'label': 'Cajero'},
          ],
        }),
        languageCode: 'es',
        onAction: (_) {},
      ),
      throwsA(isA<SduiPropsException>()),
    );
  });
}
