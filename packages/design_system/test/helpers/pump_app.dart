import 'dart:math';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio between two colors (1:1 to 21:1).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

extension PumpDesignSystem on WidgetTester {
  /// Pumps [child] inside the app theme, optionally with a text scale and a
  /// narrow phone-sized surface.
  Future<void> pumpWithTheme(
    Widget child, {
    ThemeData? theme,
    double textScale = 1,
    Size surfaceSize = const Size(360, 640),
  }) async {
    await binding.setSurfaceSize(surfaceSize);
    addTearDown(() => binding.setSurfaceSize(null));
    await pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: surfaceSize,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
  }
}
