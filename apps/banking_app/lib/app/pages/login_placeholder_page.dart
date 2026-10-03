import 'package:banking_app/app/router/app_routes.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder for the login screen, replaced by the auth feature.
class LoginPlaceholderPage extends StatelessWidget {
  const LoginPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            children: [
              Expanded(
                child: AppEmptyView(
                  icon: Icons.lock_outline,
                  title: l10n.loginTitle,
                  message: l10n.loginPlaceholderMessage,
                ),
              ),
              AppButton(
                label: l10n.continueAction,
                icon: Icons.arrow_forward,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
