import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

import '../../helpers/fakes.dart';

Finder _appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('a push received in the foreground shows a banner to open it', (
    tester,
  ) async {
    final push = FakePushService();
    await pumpApp(tester, signedInUser: testUser, push: push);

    push.foreground.add(
      const PushMessage(
        title: 'Recibiste una transferencia',
        body: 'Revisa tus movimientos',
        route: '/accounts',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Recibiste una transferencia\nRevisa tus movimientos'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();

    expect(_appBarTitle('Cuentas'), findsOneWidget);
  });

  testWidgets('without a valid route the banner has no action', (tester) async {
    final push = FakePushService();
    await pumpApp(tester, signedInUser: testUser, push: push);

    push.foreground.add(const PushMessage(title: 'Aviso', route: '/login'));
    await tester.pumpAndSettle();

    expect(find.text('Aviso'), findsOneWidget);
    expect(find.text('Ver'), findsNothing);
  });

  testWidgets('tapping a notification opens its screen', (tester) async {
    final push = FakePushService();
    await pumpApp(tester, signedInUser: testUser, push: push);

    push.opened.add(const PushMessage(route: '/fx'));
    await tester.pumpAndSettle();

    expect(find.text('Cotizador'), findsOneWidget);
  });

  testWidgets('the debug panel shows the token and copies it', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpApp(
      tester,
      signedInUser: testUser,
      config: AppConfig.dev,
      debugTools: DebugTools(
        chaos: ChaosController(),
        firestoreNetwork: FirestoreNetworkSwitch(({required enabled}) async {}),
        push: FakePushService(currentToken: 'device-token-123'),
      ),
    );
    await tester.tap(_tab('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panel de depuración'));
    await tester.pumpAndSettle();
    final copy = find.text('Copiar token');
    await tester.scrollUntilVisible(
      copy,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(copy);
    await tester.pumpAndSettle();

    expect(find.text('device-token-123'), findsOneWidget);
    await tester.tap(copy);
    await tester.pumpAndSettle();

    expect(copied, ['device-token-123']);
    expect(find.text('Token copiado'), findsOneWidget);
  });
}
