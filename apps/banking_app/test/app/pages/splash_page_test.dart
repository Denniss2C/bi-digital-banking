import 'package:banking_app/app/pages/splash_page.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('continues the native splash: the mark on navy, centered', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashPage(),
      ),
    );
    // No pumpAndSettle: the loading spinner never stops.
    await tester.pump();

    final logo = find.byType(NexoLogo);
    expect(tester.widget<NexoLogo>(logo).markOnly, isTrue);
    // Same size and position as the native splash, so the launch has no
    // jump: the loading indicator must not push the mark up.
    expect(tester.getSize(logo), const Size.square(SplashPage.markSize));
    expect(tester.getCenter(logo), tester.getCenter(find.byType(Scaffold)));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.navy,
    );
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    semantics.dispose();
  });
}
