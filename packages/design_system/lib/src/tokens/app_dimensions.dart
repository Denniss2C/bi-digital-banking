import 'package:flutter/painting.dart';

/// 8 pt spacing grid from DESIGN.md.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Side margin of every screen.
  static const double screenMargin = md;

  /// Minimum height/width of anything tappable.
  static const double minTouchTarget = 48;
}

/// Corner radii from DESIGN.md.
abstract final class AppRadius {
  static const double small = 4;
  static const double button = 12;
  static const double card = 16;
  static const double pill = 999;

  static const buttonBorder = BorderRadius.all(Radius.circular(button));
  static const cardBorder = BorderRadius.all(Radius.circular(card));
  static const pillBorder = BorderRadius.all(Radius.circular(pill));
}

/// Ambient shadows from DESIGN.md ("Elevation & Depth").
abstract final class AppShadows {
  /// Cards and modules.
  static const level1 = [
    BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(
      color: Color(0x050F172A),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];

  /// Sheets and modals.
  static const level2 = [
    BoxShadow(
      color: Color(0x140F172A),
      offset: Offset(0, 10),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x080F172A),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];

  /// Navy hero cards (balance card).
  static const hero = [
    BoxShadow(
      color: Color(0x4D1B2A41),
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -8,
    ),
  ];
}
