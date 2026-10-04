import 'package:design_system/src/tokens/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Notice shown above cached content while there is no connection, e.g.
/// "Sin conexión · mostrando tus últimos datos". Announced when it appears.
class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: scheme.inverseSurface,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.cloud_off_outlined,
                size: 20,
                color: scheme.onInverseSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
