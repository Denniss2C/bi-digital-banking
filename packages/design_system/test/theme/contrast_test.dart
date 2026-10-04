import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// WCAG AA for normal text.
const _aa = 4.5;

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    final s = theme.colorScheme;
    final c = theme.extension<AppSemanticColors>()!;

    final pairs = <String, (Color, Color)>{
      'onPrimary on primary (button text)': (s.onPrimary, s.primary),
      'onSecondary on secondary': (s.onSecondary, s.secondary),
      'onSurface on surface': (s.onSurface, s.surface),
      'onSurface on card': (s.onSurface, c.card),
      'onSurfaceVariant on surface': (s.onSurfaceVariant, s.surface),
      'onSurfaceVariant on card': (s.onSurfaceVariant, c.card),
      'onSurface on tertiary button': (s.onSurface, s.surfaceContainer),
      'onPrimaryContainer on primaryContainer': (
        s.onPrimaryContainer,
        s.primaryContainer,
      ),
      'onSecondaryContainer on secondaryContainer': (
        s.onSecondaryContainer,
        s.secondaryContainer,
      ),
      'onTertiary on tertiary': (s.onTertiary, s.tertiary),
      'onError on error': (s.onError, s.error),
      'onErrorContainer on errorContainer': (
        s.onErrorContainer,
        s.errorContainer,
      ),
      'positive amount on card': (c.positive, c.card),
      'positive amount on surface': (c.positive, s.surface),
      'negative amount on card': (c.negative, c.card),
      'negative amount on surface': (c.negative, s.surface),
      'warning on card': (c.warning, c.card),
      'onHeroSurface on heroSurface': (c.onHeroSurface, c.heroSurface),
      'link on card': (c.link, c.card),
      'link on surface': (c.link, s.surface),
    };

    group('$name theme meets WCAG AA', () {
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () {
          final ratio = contrastRatio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(_aa),
            reason: '$label is ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    });
  }

  group('why the theme deviates from the original design', () {
    test('white text on the brand orange fails AA', () {
      expect(contrastRatio(Colors.white, AppColors.orange), lessThan(_aa));
    });

    test("the design's green and red fail AA as text on white", () {
      expect(
        contrastRatio(const Color(0xFF10B981), Colors.white),
        lessThan(_aa),
      );
      expect(
        contrastRatio(const Color(0xFFEF4444), Colors.white),
        lessThan(_aa),
      );
    });
  });
}
