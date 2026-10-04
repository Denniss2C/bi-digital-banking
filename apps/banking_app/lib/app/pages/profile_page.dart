import 'package:auth/auth.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Profile tab: current account and sign out. Signing out changes the
/// session and the router sends the user back to the login.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProfile)),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          final user = switch (state) {
            SessionAuthenticated(:final user) => user,
            _ => null,
          };
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              if (user != null)
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(radius: 24, child: Text(_initials(user))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user.displayName != null)
                              Text(
                                user.displayName!,
                                style: theme.textTheme.titleMedium,
                              ),
                            Text(
                              l10n.profileSignedInAs(user.email),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.signOutAction,
                icon: Icons.logout,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.read<SessionCubit>().signOut(),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _initials(AppUser user) {
    final source = user.displayName?.trim().isNotEmpty ?? false
        ? user.displayName!
        : user.email;
    return source
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
        .join();
  }
}
