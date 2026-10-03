import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:design_system/src/tokens/app_dimensions.dart';
import 'package:flutter/material.dart';

enum AppCardVariant {
  /// White module with a 1 px border and ambient shadow.
  standard,

  /// Navy card for key figures (e.g. the balance card), with light content.
  hero,
}

/// Card module of the design system (16 px radius). Tappable when [onTap] is
/// given, with ripple and button semantics.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.standard,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.semanticsLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;

  /// Optional summary read by screen readers instead of the inner texts.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final isHero = variant == AppCardVariant.hero;

    Widget content = Padding(padding: padding, child: child);
    if (isHero) {
      content = DefaultTextStyle.merge(
        style: TextStyle(color: colors.onHeroSurface),
        child: IconTheme.merge(
          data: IconThemeData(color: colors.onHeroSurface),
          child: content,
        ),
      );
    }

    final summarize = semanticsLabel != null;
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticsLabel,
      // Excluding the children also drops the InkWell's tap action, so the
      // summarized node must expose it itself.
      excludeSemantics: summarize,
      onTap: summarize ? onTap : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isHero ? colors.heroSurface : colors.card,
          borderRadius: AppRadius.cardBorder,
          border: isHero ? null : Border.all(color: colors.border),
          boxShadow: isHero ? AppShadows.hero : AppShadows.level1,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.cardBorder,
            child: content,
          ),
        ),
      ),
    );
  }
}
