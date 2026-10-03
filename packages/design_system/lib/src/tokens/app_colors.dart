import 'package:flutter/painting.dart';

/// Raw palette of the "Nexo Digital" design (`docs/design/DESIGN.md`).
///
/// Widgets should read colors from the theme (`ColorScheme` and
/// `AppSemanticColors`), not from here. Contrast ratios are WCAG 2.x and are
/// checked by `test/theme/contrast_test.dart`.
abstract final class AppColors {
  // Brand.
  static const orange = Color(0xFFF28C28);
  static const orangePressed = Color(0xFFD97706);
  static const orangeContainer = Color(0xFFFFDCC3);
  static const onOrangeContainer = Color(0xFF2F1500);
  static const orangeDarkContainer = Color(0xFF6E3900);
  static const navy = Color(0xFF1B2A41);
  static const blueContainer = Color(0xFFD1E0FF);

  // Neutrals (light theme).
  static const white = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF8FAFC);
  static const subtle = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const muted = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);

  // Neutrals (dark theme, derived: DESIGN.md only defines light mode).
  static const darkCard = navy;
  static const darkBorder = Color(0xFF334155);
  static const darkOutline = Color(0xFF94A3B8);
  static const darkContainerHigh = Color(0xFF22324B);

  // Semantics. The design's #10B981 (2.54:1) and #EF4444 (3.76:1) fail AA
  // as text on white, so text uses these darker tones instead.
  static const positive = Color(0xFF006C49); // 6.48:1 on white
  static const negative = Color(0xFFBA1A1A); // 6.46:1 on white
  static const warning = Color(0xFFB45309); // 5.02:1 on white
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Semantics on dark surfaces.
  static const positiveDark = Color(0xFF34D399); // 7.51:1 on navy
  static const onPositiveDark = Color(0xFF003824);
  static const negativeDark = Color(0xFFF87171); // 5.22:1 on navy
  static const warningDark = Color(0xFFFBBF24); // 8.65:1 on navy
  static const errorDark = Color(0xFFFFB4AB);
  static const onErrorDark = Color(0xFF690005);
}
