/// Route paths of the app shell. Features add their own sub-routes here.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';

  // Bottom navigation tabs (one StatefulShellRoute branch each).
  static const home = '/home';
  static const accounts = '/accounts';
  static const fx = '/fx';
  static const profile = '/profile';
}
