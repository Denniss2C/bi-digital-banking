import 'dart:async';

import 'package:banking_app/app/push/push_coordinator.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:notifications/notifications.dart';

/// Shows the notifications that arrive while the app is open (Android shows
/// nothing in that case), with an action to open their screen.
class ForegroundPushListener extends StatefulWidget {
  const ForegroundPushListener({
    required this.coordinator,
    required this.child,
    super.key,
  });

  final PushCoordinator coordinator;
  final Widget child;

  @override
  State<ForegroundPushListener> createState() => _ForegroundPushListenerState();
}

class _ForegroundPushListenerState extends State<ForegroundPushListener> {
  late final StreamSubscription<PushMessage> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.coordinator.foregroundMessages.listen(_show);
  }

  void _show(PushMessage message) {
    final text = [message.title, message.body].nonNulls.join('\n');
    if (text.isEmpty || !mounted) return;
    final route = message.route;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 6),
        action: route != null && AppRoutes.isAppLocation(route)
            ? SnackBarAction(
                label: context.l10n.pushOpen,
                onPressed: () => widget.coordinator.open(message),
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
