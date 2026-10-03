import 'package:banking_app/app/pages/coming_soon_page.dart';
import 'package:banking_app/app/pages/login_placeholder_page.dart';
import 'package:banking_app/app/pages/splash_page.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:banking_app/app/shell/home_shell.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds the app router: splash → login → home shell with four tabs.
///
/// Session-based redirects (login/home) arrive with the auth feature.
GoRouter createRouter({String initialLocation = AppRoutes.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPlaceholderPage(),
      ),
      // Each tab keeps its own navigation stack and state.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          _tab(AppRoutes.home, Icons.home_outlined, (l10n) => l10n.tabHome),
          _tab(
            AppRoutes.accounts,
            Icons.account_balance_wallet_outlined,
            (l10n) => l10n.tabAccounts,
          ),
          _tab(AppRoutes.fx, Icons.currency_exchange, (l10n) => l10n.tabFx),
          _tab(
            AppRoutes.profile,
            Icons.person_outline,
            (l10n) => l10n.tabProfile,
          ),
        ],
      ),
    ],
  );
}

/// Placeholder branch until each feature provides its own screen.
StatefulShellBranch _tab(
  String path,
  IconData icon,
  String Function(AppLocalizations l10n) title,
) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (context, state) =>
            ComingSoonPage(title: title(context.l10n), icon: icon),
      ),
    ],
  );
}
