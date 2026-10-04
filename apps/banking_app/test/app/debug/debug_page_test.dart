import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fakes.dart';

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder _appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

void main() {
  late List<bool> firestoreCalls;
  late DebugTools tools;
  late FakeAccountsRepository accounts;
  late FakePersonalizationSource source;

  setUp(() {
    firestoreCalls = [];
    tools = DebugTools(
      chaos: ChaosController(),
      firestoreNetwork: FirestoreNetworkSwitch(
        ({required enabled}) async => firestoreCalls.add(enabled),
      ),
      push: FakePushService(currentToken: 'device-token-123'),
    );
    accounts = FakeAccountsRepository();
    source = FakePersonalizationSource();
  });

  Future<void> openPanel(WidgetTester tester) async {
    await pumpApp(
      tester,
      signedInUser: testUser,
      config: AppConfig.dev,
      debugTools: tools,
      accountsRepository: accounts,
      personalization: source,
    );
    await tester.tap(_tab('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panel de depuración'));
    await tester.pumpAndSettle();
  }

  // scrollUntilVisible stops once the widget is built, which can be in the
  // list's cache area below the screen; ensureVisible brings it on screen.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('prod has no entry and no route to the panel', (tester) async {
    await pumpApp(tester, signedInUser: testUser);
    await tester.tap(_tab('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Panel de depuración'), findsNothing);

    GoRouter.of(tester.element(find.byType(NavigationBar))).go(AppRoutes.debug);
    await tester.pumpAndSettle();
    expect(_appBarTitle('Panel de depuración'), findsNothing);
  });

  testWidgets('chaos mode drives the HTTP failures', (tester) async {
    await openPanel(tester);

    await tester.tap(find.text('Activar modo caos'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider).first, const Offset(300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sin red (HTTP)'));
    await tester.pumpAndSettle();

    final config = tools.chaos.value;
    expect(config.enabled, isTrue);
    expect(config.latency, greaterThan(Duration.zero));
    expect(config.offline, isTrue);
  });

  testWidgets('chaos sliders are disabled while chaos mode is off', (
    tester,
  ) async {
    await openPanel(tester);

    await tester.drag(find.byType(Slider).first, const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(tools.chaos.value, const ChaosConfig());
  });

  testWidgets('Firestore can be turned off and back on', (tester) async {
    await openPanel(tester);
    final online = find.text('Firestore conectado');
    await scrollTo(tester, online);

    await tester.tap(online);
    await tester.pumpAndSettle();
    expect(tools.firestoreNetwork.value, isFalse);

    await tester.tap(online);
    await tester.pumpAndSettle();
    expect(firestoreCalls, [false, true]);
    expect(tools.firestoreNetwork.value, isTrue);
  });

  testWidgets('choosing a segment saves it for the customer', (tester) async {
    await openPanel(tester);
    await scrollTo(tester, find.text('saver'));

    await tester.tap(find.text('saver'));
    await tester.pumpAndSettle();

    expect(accounts.segmentsSet, ['saver']);
  });

  testWidgets('shows the flags and fetches Remote Config on demand', (
    tester,
  ) async {
    await openPanel(tester);
    final fetch = find.text('Pedir valores ahora');
    await scrollTo(tester, fetch);

    expect(find.text('feature_transfers_enabled'), findsOneWidget);

    await tester.tap(fetch);
    await tester.pumpAndSettle();

    expect(source.refreshes, 1);
  });
}
