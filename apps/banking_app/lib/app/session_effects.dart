import 'dart:async';
import 'dart:developer' as developer;

import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';

/// Session side effects that involve more than one feature. The shell
/// composes them, so `auth` and `accounts` never depend on each other.
///
/// On sign-in it prepares the customer's opening data (idempotent).
class SessionEffects {
  SessionEffects({required SessionCubit session, required this.accounts}) {
    _onSession(session.state);
    _subscription = session.stream.listen(_onSession);
  }

  final AccountsRepository accounts;
  late final StreamSubscription<SessionState> _subscription;

  /// Last user (id and name) already handled; `userChanges` re-emits on
  /// profile updates, and the name matters for the profile document.
  String? _handled;

  void _onSession(SessionState state) {
    if (state is! SessionAuthenticated) {
      _handled = null;
      return;
    }
    final user = state.user;
    final key = '${user.id}|${user.displayName}';
    if (key == _handled) return;
    _handled = key;

    unawaited(
      accounts
          .ensureOpeningData(
            userId: user.id,
            name: user.displayName ?? '',
            email: user.email,
          )
          .then(
            (result) => result.match(
              (failure) => developer.log(
                'Opening data failed: ${failure.message}',
                name: 'session_effects',
              ),
              (_) {},
            ),
          ),
    );
  }

  Future<void> dispose() => _subscription.cancel();
}
