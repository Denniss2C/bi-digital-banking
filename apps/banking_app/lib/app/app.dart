import 'package:banking_app/app/config/app_config.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Root widget. Routing and DI arrive with the app shell.
class App extends StatelessWidget {
  const App({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // The DEV ribbon replaces Flutter's DEBUG banner in the same corner.
      debugShowCheckedModeBanner: false,
      builder: (context, child) => config.enableDebugTools
          ? Banner(
              message: 'DEV',
              location: BannerLocation.topEnd,
              child: child!,
            )
          : child!,
      home: Scaffold(body: Center(child: Text(config.appName))),
    );
  }
}
