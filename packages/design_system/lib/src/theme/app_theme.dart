import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:design_system/src/tokens/app_colors.dart';
import 'package:design_system/src/tokens/app_dimensions.dart';
import 'package:design_system/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// Light and dark themes of the app, built from the design tokens.
///
/// The color schemes are explicit (not `ColorScheme.fromSeed`) so the brand
/// colors stay exact. Text on the orange primary is navy, not white, to pass
/// WCAG AA (5.88:1 instead of 2.45:1).
abstract final class AppTheme {
  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.orange,
    onPrimary: AppColors.navy,
    primaryContainer: AppColors.orangeContainer,
    onPrimaryContainer: AppColors.onOrangeContainer,
    secondary: AppColors.navy,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.blueContainer,
    onSecondaryContainer: AppColors.navy,
    tertiary: AppColors.positive,
    onTertiary: AppColors.white,
    error: AppColors.negative,
    onError: AppColors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.canvas,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.muted,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.canvas,
    surfaceContainer: AppColors.subtle,
    surfaceContainerHigh: AppColors.border,
    surfaceContainerHighest: AppColors.slate300,
    outline: AppColors.muted,
    outlineVariant: AppColors.border,
    inverseSurface: AppColors.navy,
    onInverseSurface: AppColors.white,
    inversePrimary: AppColors.orangeContainer,
  );

  /// Derived from the same tokens: ink canvas, navy cards, lighter accents.
  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.orange,
    onPrimary: AppColors.navy,
    primaryContainer: AppColors.orangeDarkContainer,
    onPrimaryContainer: AppColors.orangeContainer,
    secondary: AppColors.blueContainer,
    onSecondary: AppColors.navy,
    secondaryContainer: AppColors.darkBorder,
    onSecondaryContainer: AppColors.blueContainer,
    tertiary: AppColors.positiveDark,
    onTertiary: AppColors.onPositiveDark,
    error: AppColors.errorDark,
    onError: AppColors.onErrorDark,
    errorContainer: AppColors.onErrorContainer,
    onErrorContainer: AppColors.errorContainer,
    surface: AppColors.ink,
    onSurface: AppColors.canvas,
    onSurfaceVariant: AppColors.slate300,
    surfaceContainerLowest: AppColors.ink,
    surfaceContainerLow: AppColors.ink,
    surfaceContainer: AppColors.darkCard,
    surfaceContainerHigh: AppColors.darkContainerHigh,
    surfaceContainerHighest: AppColors.darkBorder,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkBorder,
    inverseSurface: AppColors.canvas,
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.orangePressed,
  );

  static ThemeData light() => _build(lightColorScheme, AppSemanticColors.light);

  static ThemeData dark() => _build(darkColorScheme, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final textTheme = AppTypography.textTheme.apply(
      fontFamily: AppTypography.fontFamily,
      package: AppTypography.package,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      package: AppTypography.package,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.buttonBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorder,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorder,
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      dividerTheme: DividerThemeData(color: semantic.border, thickness: 1),
      // TextButton defaults to the orange primary, which fails AA as text on
      // light surfaces; links use the semantic link color instead.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: semantic.link,
          minimumSize: const Size(48, AppSpacing.minTouchTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      // Selected segment in navy (secondary), as in the design's tabs.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.secondary,
          selectedForegroundColor: scheme.onSecondary,
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(48, AppSpacing.minTouchTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      // The design marks the active tab in orange text, which fails AA on
      // white (2.45:1). The orange accent lives in the indicator pill; icons
      // and labels use AA colors.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: semantic.card,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
