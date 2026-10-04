import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/debug/debug_page.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:banking_app/app/home/home_page.dart';
import 'package:banking_app/app/pages/feature_unavailable_page.dart';
import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/app/pages/profile_page.dart';
import 'package:banking_app/app/pages/splash_page.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:banking_app/app/router/auth_redirect.dart';
import 'package:banking_app/app/router/stream_listenable.dart';
import 'package:banking_app/app/shell/home_shell.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_rates/fx_rates.dart';
import 'package:go_router/go_router.dart';

/// Builds the app router: splash → onboarding / login → home shell.
///
/// The shell composes the auth feature here: it decides what to persist when
/// onboarding ends and redirects on every session change.
GoRouter createRouter({
  required SessionCubit session,
  required PersonalizationCubit personalization,
  required OnboardingRepository onboardingRepository,
  required AuthRepository authRepository,
  required AccountsRepository accountsRepository,
  required FxRatesRepository fxRatesRepository,
  DebugTools? debugTools,
  String initialLocation = AppRoutes.splash,
}) {
  // Tabs are only reachable when signed in (see authRedirect).
  String userId() => switch (session.state) {
    SessionAuthenticated(:final user) => user.id,
    _ => '',
  };

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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => HomePage(
                  accountsRepository: accountsRepository,
                  fxRatesRepository: fxRatesRepository,
                  userId: userId(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.accounts,
                // The transfer button follows its remote flag live.
                builder: (context, state) =>
                    BlocSelector<
                      PersonalizationCubit,
                      PersonalizationConfig,
                      bool
                    >(
                      bloc: personalization,
                      selector: (config) => config.flags.transfers,
                      builder: (context, transfersEnabled) => AccountsPage(
                        repository: accountsRepository,
                        userId: userId(),
                        onOpenAccount: (account) =>
                            context.go(AppRoutes.accountDetail(account.id)),
                        onTransfer: transfersEnabled
                            ? () => context.go(AppRoutes.transfer)
                            : null,
                      ),
                    ),
                routes: [
                  // Declared before ':accountId' so 'transfer' is not an id.
                  GoRoute(
                    path: 'transfer',
                    redirect: (context, state) =>
                        personalization.state.flags.transfers
                        ? null
                        : AppRoutes.accounts,
                    builder: (context, state) => TransferPage(
                      repository: accountsRepository,
                      userId: userId(),
                      onDone: () => context.go(AppRoutes.accounts),
                    ),
                  ),
                  GoRoute(
                    path: ':accountId',
                    builder: (context, state) => AccountDetailPage(
                      repository: accountsRepository,
                      userId: userId(),
                      accountId: state.pathParameters['accountId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.fx,
                // Divisas follows its remote flag live.
                builder: (context, state) =>
                    BlocSelector<
                      PersonalizationCubit,
                      PersonalizationConfig,
                      bool
                    >(
                      bloc: personalization,
                      selector: (config) => config.flags.fx,
                      builder: (context, fxEnabled) => fxEnabled
                          ? FxPage(repository: fxRatesRepository)
                          : FeatureUnavailablePage(
                              title: context.l10n.tabFx,
                              icon: Icons.currency_exchange,
                            ),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => ProfilePage(
                  onOpenDebug: debugTools == null
                      ? null
                      : () => context.go(AppRoutes.debug),
                ),
                routes: [
                  // Dev flavor only: in prod the route does not exist.
                  if (debugTools != null)
                    GoRoute(
                      path: 'debug',
                      builder: (context, state) => DebugPage(
                        tools: debugTools,
                        accounts: accountsRepository,
                        userId: userId(),
                      ),
                    ),
                ],
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
