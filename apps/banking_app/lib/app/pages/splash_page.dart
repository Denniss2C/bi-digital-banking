import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shown while Firebase restores the stored session. The router leaves it
/// as soon as the session is known (see `authRedirect`).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: AppLoading(semanticsLabel: context.l10n.loading));
  }
}
