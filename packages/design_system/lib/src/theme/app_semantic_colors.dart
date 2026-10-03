import 'package:design_system/src/tokens/app_colors.dart';
import 'package:flutter/material.dart';

/// Colors with banking meaning that `ColorScheme` does not cover.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.card,
    required this.border,
    required this.heroSurface,
    required this.onHeroSurface,
  });

  static const light = AppSemanticColors(
    positive: AppColors.positive,
    negative: AppColors.negative,
    warning: AppColors.warning,
    card: AppColors.white,
    border: AppColors.border,
    heroSurface: AppColors.navy,
    onHeroSurface: AppColors.white,
  );

  static const dark = AppSemanticColors(
    positive: AppColors.positiveDark,
    negative: AppColors.negativeDark,
    warning: AppColors.warningDark,
    card: AppColors.darkCard,
    border: AppColors.darkBorder,
    heroSurface: AppColors.navy,
    onHeroSurface: AppColors.white,
  );

  /// Incoming money (credits, income).
  final Color positive;

  /// Outgoing money (debits, expenses).
  final Color negative;

  /// Pending or limited states.
  final Color warning;

  /// Background of standard cards.
  final Color card;

  /// 1 px borders and dividers.
  final Color border;

  /// Navy "hero" cards such as the balance card.
  final Color heroSurface;
  final Color onHeroSurface;

  @override
  AppSemanticColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? card,
    Color? border,
    Color? heroSurface,
    Color? onHeroSurface,
  }) {
    return AppSemanticColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      card: card ?? this.card,
      border: border ?? this.border,
      heroSurface: heroSurface ?? this.heroSurface,
      onHeroSurface: onHeroSurface ?? this.onHeroSurface,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      onHeroSurface: Color.lerp(onHeroSurface, other.onHeroSurface, t)!,
    );
  }
}

/// Shortcut: `context.semanticColors.positive`.
extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
