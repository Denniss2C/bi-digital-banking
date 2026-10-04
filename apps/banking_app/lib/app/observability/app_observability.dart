import 'dart:async';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

/// App-wide signals for [Telemetry]:
/// - the screen on every navigation, by route pattern (`/accounts/:accountId`,
///   never the account id itself);
/// - the user (pseudonymous Firebase uid) on every session change;
/// - `login` when someone signs in. A session restored at startup is not a
///   login.
class AppObservability {
  AppObservability({
    required this.telemetry,
    required this.session,
    required this.router,
  });

  final Telemetry telemetry;
  final SessionCubit session;
  final GoRouter router;

  StreamSubscription<SessionState>? _subscription;
  SessionState? _previous;
  String? _lastScreen;

  void start() {
    router.routerDelegate.addListener(_onRoute);
    _onRoute();
    _onSession(session.state);
    _subscription = session.stream.listen(_onSession);
  }

  void _onRoute() {
    final screen = router.routerDelegate.currentConfiguration.fullPath;
    if (screen.isEmpty || screen == _lastScreen) return;
    _lastScreen = screen;
    telemetry.screen(screen);
  }

  void _onSession(SessionState state) {
    final previous = _previous;
    _previous = state;
    final userId = switch (state) {
      SessionAuthenticated(:final user) => user.id,
      _ => null,
    };
    final previousId = switch (previous) {
      SessionAuthenticated(:final user) => user.id,
      _ => null,
    };
    if (userId == previousId && previous != null) return;
    telemetry.setUser(userId);
    if (userId != null && previous is SessionUnauthenticated) {
      telemetry.event('login');
    }
  }

  Future<void> dispose() async {
    router.routerDelegate.removeListener(_onRoute);
    await _subscription?.cancel();
  }
}
