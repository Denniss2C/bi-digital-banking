import 'package:banking_app/app/home/default_home_layout.dart';
import 'package:banking_app/app/home/home_page.dart';
import 'package:banking_app/app/home/home_registry.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

import '../../helpers/fakes.dart';

/// Types in the embedded layout whose feature is not built yet.
const _pendingTypes = {'fx_widget'};

void main() {
  final registry = createHomeRegistry(
    accountsRepository: FakeAccountsRepository(),
    userId: 'uid-1',
  );
  final layout = parseSduiLayout(
    defaultHomeLayout,
  ).getOrElse((error) => fail(error.message));

  test('the embedded home layout parses without issues', () {
    expect(layout.issues, isEmpty);
  });

  test('every component of the embedded layout is registered', () {
    final missing = {
      for (final node in layout.components)
        if (!registry.supports(node.type)) node.type,
    };
    expect(missing, _pendingTypes);
  });

  test('every action of the embedded layout opens a screen of the app', () {
    final routes = RegExp(
      r'"route": "([^"]+)"',
    ).allMatches(defaultHomeLayout).map((match) => match.group(1)!);
    expect(routes, isNotEmpty);
    for (final route in routes) {
      expect(AppRoutes.isAppLocation(route), isTrue, reason: route);
    }
  });

  test('server-driven navigation only accepts screens of the app', () {
    expect(AppRoutes.isAppLocation('/accounts/transfer'), isTrue);
    expect(AppRoutes.isAppLocation('/fx'), isTrue);
    expect(AppRoutes.isAppLocation('/login'), isFalse);
    expect(AppRoutes.isAppLocation('/fxx'), isFalse);
    expect(AppRoutes.isAppLocation('https://evil.example/accounts'), isFalse);
    expect(AppRoutes.isAppLocation('//evil.example/accounts'), isFalse);
    expect(AppRoutes.isAppLocation(AppRoutes.debug), isFalse);
  });

  test('the greeting uses the first name only', () {
    expect(firstName('Mateo Moreno'), 'Mateo');
    expect(firstName('  Ana  '), 'Ana');
    expect(firstName(''), isNull);
    expect(firstName(null), isNull);
  });
}
