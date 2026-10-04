import 'package:banking_app/app/personalization/personalization_config.dart';

/// Route paths of the app shell. Features add their own sub-routes here.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';

  /// Sign in; `?mode=signup` opens the create-account form.
  static const login = '/login';
  static const signUp = '$login?mode=signup';

  // Bottom navigation tabs (one StatefulShellRoute branch each).
  static const home = '/home';
  static const accounts = '/accounts';
  static const transfer = '$accounts/transfer';
  static String accountDetail(String accountId) => '$accounts/$accountId';
  static const fx = '/fx';
  static const profile = '/profile';

  /// Debug panel; only exists in the dev flavor.
  static const debug = '$profile/debug';

  /// Whether [location] is a screen of this app version. Server-driven
  /// navigation (SDUI actions) may only open these.
  static bool isAppLocation(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
    // Dev tooling is never a destination for the server.
    if (uri.path == debug || uri.path.startsWith('$debug/')) return false;
    return const [
      home,
      accounts,
      fx,
      profile,
    ].any((tab) => uri.path == tab || uri.path.startsWith('$tab/'));
  }

  /// Whether the feature behind [location] is enabled by its remote flag.
  static bool isEnabled(String location, FeatureFlags flags) {
    final path = Uri.tryParse(location)?.path ?? location;
    if (path == transfer || path.startsWith('$transfer/')) {
      return flags.transfers;
    }
    if (path == fx || path.startsWith('$fx/')) return flags.fx;
    return true;
  }
}
