import 'package:flutter/material.dart';

/// Inter type scale from DESIGN.md, mapped to Material 3 text roles.
///
/// The font family itself is set once in `ThemeData` (Inter, bundled in this
/// package), so these styles only define size, weight, height and tracking.
abstract final class AppTypography {
  static const fontFamily = 'Inter';
  static const package = 'design_system';

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight, {
    double trackingEm = 0,
  }) {
    return TextStyle(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: trackingEm * size,
    );
  }

  static final textTheme = TextTheme(
    displayLarge: _style(40, 48, FontWeight.w700, trackingEm: -0.03),
    // headline-lg-mobile: the app is mobile-first.
    headlineLarge: _style(26, 32, FontWeight.w700, trackingEm: -0.02),
    headlineMedium: _style(22, 28, FontWeight.w600, trackingEm: -0.01),
    headlineSmall: _style(18, 24, FontWeight.w600),
    titleLarge: _style(18, 24, FontWeight.w600),
    titleMedium: _style(16, 24, FontWeight.w600),
    titleSmall: _style(14, 20, FontWeight.w600),
    bodyLarge: _style(16, 24, FontWeight.w400),
    bodyMedium: _style(14, 20, FontWeight.w400),
    bodySmall: _style(12, 16, FontWeight.w400),
    labelLarge: _style(14, 20, FontWeight.w600, trackingEm: 0.01),
    labelMedium: _style(12, 16, FontWeight.w600, trackingEm: 0.02),
    labelSmall: _style(10, 12, FontWeight.w700, trackingEm: 0.04),
  );
}

/// Money and account numbers must use tabular figures (DESIGN.md), so digits
/// keep the same width and columns of amounts stay aligned.
extension TabularFigures on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
