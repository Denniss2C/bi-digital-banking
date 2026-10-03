import 'package:design_system/src/tokens/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Loading state of a screen or section.
///
/// [semanticsLabel] is required so screen readers always announce what is
/// loading (the text comes localized from the app).
class AppLoading extends StatelessWidget {
  const AppLoading({required this.semanticsLabel, this.message, super.key});

  final String semanticsLabel;

  /// Optional visible text under the spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Semantics(
        label: semanticsLabel,
        liveRegion: true,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
