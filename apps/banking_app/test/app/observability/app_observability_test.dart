import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

import '../../helpers/fakes.dart';

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  late RecordingTelemetry telemetry;

  setUp(() => telemetry = RecordingTelemetry());

  group('screens and session', () {
    testWidgets('screens are reported by route pattern, never by id', (
      tester,
    ) async {
      await pumpApp(tester, signedInUser: testUser, telemetry: telemetry);

      await tester.tap(_tab('Cuentas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cuenta de Ahorros'));
      await tester.pumpAndSettle();

      expect(
        telemetry.screens,
        containsAllInOrder(['/home', '/accounts', '/accounts/:accountId']),
      );
      expect(telemetry.screens.join(), isNot(contains('savings')));
    });

    testWidgets('a restored session sets the user but is not a login', (
      tester,
    ) async {
      await pumpApp(tester, signedInUser: testUser, telemetry: telemetry);

      expect(telemetry.users.last, 'uid-1');
      expect(telemetry.eventNames, isNot(contains('login')));
    });

    testWidgets('signing in from the login screen is a login', (tester) async {
      await pumpApp(tester, hasSeenOnboarding: true, telemetry: telemetry);

      await tester.enterText(find.byType(TextField).at(0), 'mateo@nexo.ec');
      await tester.enterText(find.byType(TextField).at(1), 'nexo2026');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(telemetry.eventNames, contains('login'));
      expect(telemetry.users.last, 'uid-1');
    });
  });

  group('home', () {
    testWidgets('reports where its layout came from', (tester) async {
      await pumpApp(
        tester,
        signedInUser: testUser,
        telemetry: telemetry,
        personalization: FakePersonalizationSource(
          current: const PersonalizationConfig(homeLayout: '{oops'),
        ),
      );

      final layout = telemetry.events.firstWhere(
        (event) => event.$1 == 'home_layout',
      );
      expect(layout.$2, {'source': 'fallback', 'issues': 1});
    });

    testWidgets('a failing component is an error and an event', (tester) async {
      const layout =
          '{"components": [{"type": "promo_banner", "props": {}}, '
          '{"type": "quick_actions", "props": {"items": [{"label": "Cuentas", '
          '"action": {"type": "navigate", "route": "/accounts"}}]}}]}';
      await pumpApp(
        tester,
        signedInUser: testUser,
        telemetry: telemetry,
        personalization: FakePersonalizationSource(
          current: const PersonalizationConfig(homeLayout: layout),
        ),
      );

      expect(telemetry.errors.first.$2, 'SDUI component "promo_banner"');
      expect(telemetry.eventNames, contains('sdui_component_failed'));
    });

    testWidgets('a feature turned off is reported when someone tries it', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signedInUser: testUser,
        telemetry: telemetry,
        personalization: FakePersonalizationSource(
          current: const PersonalizationConfig(
            flags: FeatureFlags(transfers: false),
          ),
        ),
      );

      await tester.tap(find.text('Transferir'));
      await tester.pumpAndSettle();

      expect(
        telemetry.events.where((event) => event.$1 == 'feature_unavailable'),
        hasLength(1),
      );
    });
  });

  testWidgets('an opened notification is reported with its route', (
    tester,
  ) async {
    final push = FakePushService();
    await pumpApp(
      tester,
      signedInUser: testUser,
      telemetry: telemetry,
      push: push,
    );

    push.opened.add(const PushMessage(route: '/fx'));
    await tester.pumpAndSettle();

    final opened = telemetry.events.firstWhere(
      (event) => event.$1 == 'push_opened',
    );
    expect(opened.$2, {'route': '/fx'});
  });

  testWidgets('the debug panel sends a test error and can crash the app', (
    tester,
  ) async {
    final panelTelemetry = RecordingTelemetry();
    var crashes = 0;
    await pumpApp(
      tester,
      signedInUser: testUser,
      config: AppConfig.dev,
      debugTools: DebugTools(
        chaos: ChaosController(),
        firestoreNetwork: FirestoreNetworkSwitch(({required enabled}) async {}),
        push: FakePushService(),
        telemetry: panelTelemetry,
        crash: () => crashes++,
      ),
    );
    await tester.tap(_tab('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panel de depuración'));
    await tester.pumpAndSettle();

    Future<void> tapButton(String label) async {
      final button = find.text(label);
      await tester.scrollUntilVisible(
        button,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await tapButton('Enviar error de prueba');
    expect(panelTelemetry.errors.single.$2, 'debug panel');
    expect(find.text('Error enviado a Crashlytics'), findsOneWidget);

    await tapButton('Forzar cierre de la app (crash)');
    expect(crashes, 1);
  });
}
