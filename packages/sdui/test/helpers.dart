import 'dart:math';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

/// A builder that does nothing, for registry tests.
Widget emptyComponent(
  BuildContext context,
  SduiProps props,
  SduiActionHandler onAction,
) => const SizedBox();

/// Parses [json] or fails the test.
SduiLayout layoutOf(String json) =>
    parseSduiLayout(json).getOrElse((error) => fail(error.message));

/// WCAG 2.x contrast ratio between two colors (1:1 to 21:1).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

extension PumpSdui on WidgetTester {
  /// Pumps [child] on a phone-sized, scrollable screen with the app theme.
  Future<void> pumpSdui(
    Widget child, {
    Locale locale = const Locale('es'),
    ThemeData? theme,
    double textScale = 1,
  }) async {
    await binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => binding.setSurfaceSize(null));
    await pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(),
        locale: locale,
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
