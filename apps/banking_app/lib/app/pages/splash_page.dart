import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shown while Firebase restores the stored session. The router leaves it
/// as soon as the session is known (see `authRedirect`).
///
/// It continues the native splash: navy with the mark centered at 88 dp
/// (`tool/brand_assets_test.dart`), so the launch has no jump.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  /// Size of the mark. The native splash images are rendered at this size
  /// (`make brand-assets`).
  static const markSize = 88.0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons on navy.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Stack(
          children: [
            const Center(child: NexoLogo(size: markSize, markOnly: true)),
            // Below the mark, so the mark stays exactly where the native
            // splash left it.
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.xl * 3,
              child: AppLoading(semanticsLabel: context.l10n.loading),
            ),
          ],
        ),
      ),
    );
  }
}
