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

  /// Whether [location] is a screen of this app version. Server-driven
  /// navigation (SDUI actions) may only open these.
  static bool isAppLocation(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return false;
    return const [
      home,
      accounts,
      fx,
      profile,
    ].any((tab) => uri.path == tab || uri.path.startsWith('$tab/'));
  }
}
