import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light and dark use the brand primary with navy text on it', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.colorScheme.primary, AppColors.orange);
        expect(theme.colorScheme.onPrimary, AppColors.navy);
      }
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
    });

    test('text uses the bundled Inter font', () {
      final style = AppTheme.light().textTheme.bodyMedium!;

      expect(style.fontFamily, 'packages/design_system/Inter');
      expect(style.fontSize, 14);
    });

    test('exposes the semantic colors extension in both themes', () {
      expect(
        AppTheme.light().extension<AppSemanticColors>(),
        AppSemanticColors.light,
      );
      expect(
        AppTheme.dark().extension<AppSemanticColors>(),
        AppSemanticColors.dark,
      );
    });

    test('buttons have a 48 px minimum touch target', () {
      final style = AppTheme.light().filledButtonTheme.style!;

      expect(style.minimumSize!.resolve({})!.height, AppSpacing.minTouchTarget);
    });
  });

  test('tabular figures are enabled for amounts', () {
    const style = TextStyle(fontSize: 16);

    expect(
      style.tabular.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}
