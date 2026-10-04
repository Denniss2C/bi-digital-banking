import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sdui/src/components/sdui_icons.dart';
import 'package:sdui/src/model/sdui_action.dart';
import 'package:sdui/src/model/sdui_props.dart';
import 'package:sdui/src/registry/sdui_registry.dart';

/// One shortcut of [QuickActions].
class QuickActionItem {
  const QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Filled orange, for the main shortcut (e.g. Transferir).
  final bool highlighted;
}

/// `quick_actions`: a row of shortcuts ("Operaciones frecuentes").
///
/// Props: `title` and `items`, a list of
/// `{"label", "icon", "action", "highlighted"}`. Items without a label or
/// with an unsupported action are skipped. If no item is left, the
/// component is skipped.
class QuickActions extends StatelessWidget {
  const QuickActions({required this.items, this.title, super.key});

  /// Reads the props of a `quick_actions`. Throws [SduiPropsException] when
  /// no item is valid.
  factory QuickActions.fromProps(
    SduiProps props, {
    required String languageCode,
    required SduiActionHandler onAction,
  }) {
    final items = [
      for (final item in props.objects('items'))
        if ((
              item.text('label', languageCode: languageCode),
              item.action('action'),
            )
            case (final String label, final SduiAction action))
          QuickActionItem(
            label: label,
            icon: sduiIcon(item.string('icon')),
            highlighted: item.boolean('highlighted') ?? false,
            onTap: () => onAction(action),
          ),
    ];
    if (items.isEmpty) {
      throw const SduiPropsException(
        'quick_actions needs an item with a label and a supported action',
      );
    }
    return QuickActions(
      title: props.text('title', languageCode: languageCode),
      items: items,
    );
  }

  final String? title;
  final List<QuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Four per row, as in the design. With large text, two per row so the
    // labels wrap instead of being cut.
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final columns = textScale > 1.3 ? 2 : 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Semantics(
              header: true,
              child: Text(title!, style: theme.textTheme.titleLarge),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                columns;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.md,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: _QuickActionTile(item: item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.item});

  final QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.semanticColors;
    final (background, iconColor) = item.highlighted
        ? (scheme.primary, scheme.onPrimary)
        : (colors.card, colors.link);

    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: AppRadius.cardBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: AppRadius.cardBorder,
                    border: item.highlighted
                        ? null
                        : Border.all(color: colors.border),
                    boxShadow: AppShadows.level1,
                  ),
                  child: Icon(item.icon, color: iconColor, size: 28),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
