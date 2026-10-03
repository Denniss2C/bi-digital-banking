import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/components/status_layout.dart';
import 'package:flutter/material.dart';

/// Empty state (e.g. no movements yet), with an optional action.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction go together',
       );

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return StatusLayout(
      icon: icon,
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      title: title,
      message: message,
      action: actionLabel == null
          ? null
          : AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.tertiary,
              expand: false,
            ),
    );
  }
}
