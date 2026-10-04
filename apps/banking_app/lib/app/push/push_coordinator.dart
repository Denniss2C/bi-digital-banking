import 'dart:async';
import 'dart:developer' as developer;

import 'package:auth/auth.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/notifications.dart';

/// Push notifications for the session. The shell composes them, so
/// `notifications` never depends on `auth`.
///
/// - **Sign-in:** asks for permission and saves the device token in
///   `users/{uid}.fcmTokens` (and every refreshed token).
/// - **Sign-out:** removes the token, so a shared device stops getting the
///   previous user's notifications.
/// - **Tap** on a notification (app in background or closed): opens its
///   `route` if it is a screen of the app. While signed out it waits for the
///   sign-in.
/// - **Foreground:** the system shows nothing, so [foregroundMessages] lets
///   the app show them itself.
class PushCoordinator {
  PushCoordinator({
    required this.session,
    required this.push,
    required this.tokens,
    required this.navigate,
  });

  final SessionCubit session;
  final PushService push;
  final PushTokenRegistry tokens;

  /// Opens an in-app location (the router's `go`).
  final void Function(String location) navigate;

  /// This device's current token (the debug panel shows it).
  final token = ValueNotifier<String?>(null);

  final _foreground = StreamController<PushMessage>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  String? _userId;
  String? _pendingRoute;

  /// Messages received while the app is open.
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  Future<void> start() async {
    _subscriptions
      ..add(push.foregroundMessages.listen(_foreground.add))
      ..add(push.openedMessages.listen(open))
      ..add(push.tokenRefreshes.listen(_saveToken));
    final initial = await push.initialMessage();
    if (initial != null) open(initial);
    _onSession(session.state);
    _subscriptions.add(session.stream.listen(_onSession));
  }

  /// Opens the screen of [message], if it has a valid one.
  void open(PushMessage message) {
    final route = message.route;
    // Same rule as server-driven actions: only screens of the app.
    if (route == null || !AppRoutes.isAppLocation(route)) return;
    if (_userId == null) {
      _pendingRoute = route;
    } else {
      navigate(route);
    }
  }

  void _onSession(SessionState state) {
    final userId = switch (state) {
      SessionAuthenticated(:final user) => user.id,
      _ => null,
    };
    if (userId == _userId) return;
    final previous = _userId;
    _userId = userId;

    if (userId == null) {
      final current = token.value;
      if (previous != null && current != null) {
        unawaited(tokens.remove(userId: previous, token: current));
      }
      return;
    }
    unawaited(_register());
    final pending = _pendingRoute;
    _pendingRoute = null;
    if (pending != null) navigate(pending);
  }

  Future<void> _register() async {
    try {
      final permission = await push.requestPermission();
      developer.log('Permission: ${permission.name}', name: 'push');
      final value = await push.token();
      if (value != null) await _saveToken(value);
    } on Object catch (error) {
      // No push (e.g. iOS without APNs, or no Google Play services): the app
      // keeps working without notifications.
      developer.log('Push unavailable: $error', name: 'push');
    }
  }

  Future<void> _saveToken(String value) async {
    token.value = value;
    final userId = _userId;
    if (userId == null) return;
    final result = await tokens.save(userId: userId, token: value);
    result.match(
      (failure) => developer.log('Token not saved: $failure', name: 'push'),
      (_) {},
    );
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _foreground.close();
    token.dispose();
  }
}
