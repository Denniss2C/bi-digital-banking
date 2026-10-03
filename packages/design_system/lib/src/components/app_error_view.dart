import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/components/status_layout.dart';
import 'package:flutter/material.dart';

/// Error state with a retry action. Announced by screen readers when shown.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.title,
    required this.retryLabel,
    required this.onRetry,
    this.message,
    this.icon = Icons.error_outline_rounded,
    super.key,
  });

  final String title;
  final String? message;
  final String retryLabel;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: StatusLayout(
        icon: icon,
        iconColor: Theme.of(context).colorScheme.error,
        title: title,
        message: message,
        action: AppButton(
          label: retryLabel,
          onPressed: onRetry,
          icon: Icons.refresh_rounded,
          expand: false,
        ),
      ),
    );
  }
}
