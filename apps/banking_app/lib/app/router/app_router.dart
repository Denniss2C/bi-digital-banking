import 'package:auth/auth.dart';
import 'package:banking_app/app/pages/coming_soon_page.dart';
import 'package:banking_app/app/pages/profile_page.dart';
import 'package:banking_app/app/pages/splash_page.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:banking_app/app/router/auth_redirect.dart';
import 'package:banking_app/app/router/stream_listenable.dart';
import 'package:banking_app/app/shell/home_shell.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds the app router: splash → onboarding / login → home shell.
///
/// The shell composes the auth feature here: it decides what to persist when
/// onboarding ends and redirects on every session change.
GoRouter createRouter({
  required SessionCubit session,
  required OnboardingRepository onboardingRepository,
  required AuthRepository authRepository,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: StreamListenable(session.stream),
    redirect: (context, state) => authRedirect(
      session: session.state,
      hasSeenOnboarding: onboardingRepository.hasSeenOnboarding,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => OnboardingPage(
          onFinished: () =>
              _leaveOnboarding(context, onboardingRepository, AppRoutes.signUp),
          onSignIn: () =>
              _leaveOnboarding(context, onboardingRepository, AppRoutes.login),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => AuthPage(
          repository: authRepository,
          initialMode: state.uri.queryParameters['mode'] == 'signup'
              ? AuthMode.signUp
              : AuthMode.signIn,
        ),
      ),
      // Each tab keeps its own navigation stack and state.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          _comingSoonTab(
            AppRoutes.home,
            Icons.home_outlined,
            (l10n) => l10n.tabHome,
          ),
          _comingSoonTab(
            AppRoutes.accounts,
            Icons.account_balance_wallet_outlined,
            (l10n) => l10n.tabAccounts,
          ),
          _comingSoonTab(
            AppRoutes.fx,
            Icons.currency_exchange,
            (l10n) => l10n.tabFx,
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<void> _leaveOnboarding(
  BuildContext context,
  OnboardingRepository repository,
  String destination,
) async {
  await repository.markOnboardingSeen();
  if (context.mounted) context.go(destination);
}

/// Placeholder branch until the feature that owns the tab provides a screen.
StatefulShellBranch _comingSoonTab(
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
