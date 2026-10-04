import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sdui/src/components/sdui_icons.dart';
import 'package:sdui/src/model/sdui_props.dart';
import 'package:sdui/src/registry/sdui_registry.dart';

/// Color of a [PromoBanner]. The server picks a semantic tone, never raw
/// colors, so every combination keeps the theme's tested AA contrast.
enum PromoTone {
  /// Light orange (`primaryContainer`), as in the design's promo card.
  primary,

  /// Navy, like the hero cards.
  secondary,

  /// White card with a border.
  neutral,
}

/// `promo_banner`: a campaign or content card.
///
/// Props: `title` (required), `eyebrow`, `body`, `footnote`, `icon`, `tone`
/// (`primary` by default) and `cta` (`{"label", "action"}`). The button is
/// hidden when its action is not supported.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    required this.title,
    this.eyebrow,
    this.body,
    this.footnote,
    this.icon,
    this.tone = PromoTone.primary,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  /// Reads the props of a `promo_banner`. Throws [SduiPropsException] when
  /// the title is missing.
  factory PromoBanner.fromProps(
    SduiProps props, {
    required String languageCode,
    required SduiActionHandler onAction,
  }) {
    final cta = props.object('cta');
    final ctaLabel = cta?.text('label', languageCode: languageCode);
    final ctaAction = cta?.action('action');
    final hasCta = ctaLabel != null && ctaAction != null;
    final icon = props.string('icon');
    return PromoBanner(
      title: props.requireText('title', languageCode: languageCode),
      eyebrow: props.text('eyebrow', languageCode: languageCode),
      body: props.text('body', languageCode: languageCode),
      footnote: props.text('footnote', languageCode: languageCode),
      icon: icon == null ? null : sduiIcon(icon),
      tone:
          PromoTone.values.asNameMap()[props.string('tone')] ??
          PromoTone.primary,
      ctaLabel: hasCta ? ctaLabel : null,
      onCta: hasCta ? () => onAction(ctaAction) : null,
    );
  }

  final String title;
  final String? eyebrow;
  final String? body;
  final String? footnote;
  final IconData? icon;
  final PromoTone tone;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.semanticColors;
    final (background, foreground, buttonVariant) = switch (tone) {
      PromoTone.primary => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        AppButtonVariant.secondary,
      ),
      PromoTone.secondary => (
        colors.heroSurface,
        colors.onHeroSurface,
        AppButtonVariant.primary,
      ),
      PromoTone.neutral => (
        colors.card,
        scheme.onSurface,
        AppButtonVariant.primary,
      ),
    };
    // Theme text styles carry their own color: set it explicitly on each
    // text so nothing falls back to the dark default on navy.
    TextStyle? styled(TextStyle? style) => style?.copyWith(color: foreground);

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.cardBorder,
          border: tone == PromoTone.neutral
              ? Border.all(color: colors.border)
              : null,
          boxShadow: tone == PromoTone.secondary
              ? AppShadows.hero
              : AppShadows.level1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null || eyebrow != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      if (icon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Icon(icon, size: 20, color: foreground),
                        ),
                      if (eyebrow != null)
                        Expanded(
                          child: Text(
                            eyebrow!.toUpperCase(),
                            style: styled(
                              theme.textTheme.labelMedium,
                            )?.copyWith(letterSpacing: 1),
                          ),
                        ),
                    ],
                  ),
                ),
              Semantics(
                header: true,
                child: Text(title, style: styled(theme.textTheme.titleLarge)),
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(body!, style: styled(theme.textTheme.bodyMedium)),
              ],
              if (ctaLabel != null || footnote != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (ctaLabel != null)
                      AppButton(
                        label: ctaLabel!,
                        icon: Icons.chevron_right,
                        variant: buttonVariant,
                        expand: false,
                        onPressed: onCta,
                      ),
                    if (footnote != null)
                      Text(
                        footnote!,
                        style: styled(theme.textTheme.labelSmall),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
