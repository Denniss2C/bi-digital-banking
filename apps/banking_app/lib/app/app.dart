import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root widget: session, theme, localization and routing of the app shell.
class App extends StatelessWidget {
  const App({
    required this.config,
    required this.router,
    required this.session,
    super.key,
  });

  final AppConfig config;
  final GoRouter router;
  final SessionCubit session;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: session,
      child: MaterialApp.router(
        title: config.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
        // Each feature owns its strings; the shell registers their delegates.
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          AuthLocalizations.delegate,
          AccountsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: resolveAppLocale,
        // The DEV ribbon replaces Flutter's DEBUG banner in the same corner.
        debugShowCheckedModeBanner: false,
        builder: (context, child) => config.enableDebugTools
            ? Banner(
                message: 'DEV',
                location: BannerLocation.topEnd,
                child: child!,
              )
            : child!,
      ),
    );
  }
}
