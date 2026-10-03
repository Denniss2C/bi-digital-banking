import 'package:design_system/src/tokens/app_dimensions.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant {
  /// Orange: the main action of a screen.
  primary,

  /// Navy: strong secondary action on light surfaces.
  secondary,

  /// Subtle gray: low-emphasis actions.
  tertiary,
}

/// Button of the design system: at least 48 px tall, 12 px radius, optional
/// leading icon and a loading state that keeps the label for screen readers.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Shows a spinner and ignores taps (e.g. while a request is in flight).
  final bool isLoading;

  /// Fills the available width (the default for screen-level actions).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (variant) {
      AppButtonVariant.primary => (scheme.primary, scheme.onPrimary),
      AppButtonVariant.secondary => (scheme.secondary, scheme.onSecondary),
      AppButtonVariant.tertiary => (scheme.surfaceContainer, scheme.onSurface),
    };

    final content = isLoading
        ? Semantics(
            label: label,
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      child: content,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
