import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Root widget: theme, localization and routing of the app shell.
class App extends StatelessWidget {
  const App({required this.config, required this.router, super.key});

  final AppConfig config;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: config.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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
    );
  }
}
