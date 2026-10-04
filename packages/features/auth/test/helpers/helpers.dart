import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const testUser = AppUser(
  id: 'uid-1',
  email: 'mateo@nexo.ec',
  displayName: 'Mateo',
);

extension PumpAuth on WidgetTester {
  /// Pumps [child] with the app theme and the auth strings in Spanish.
  Future<void> pumpLocalized(Widget child) async {
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AuthLocalizations.localizationsDelegates,
        supportedLocales: AuthLocalizations.supportedLocales,
        home: child,
      ),
    );
    await pumpAndSettle();
  }
}
