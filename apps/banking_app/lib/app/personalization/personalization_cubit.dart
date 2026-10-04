import 'dart:async';
import 'dart:developer' as developer;

import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:banking_app/app/personalization/personalization_source.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Current personalization (home layout and feature flags) for the session.
///
/// It starts with the values embedded in the app, then the ones cached from
/// the last session, and follows:
/// - the signed-in customer's segment (`users/{uid}.segment`): each change
///   fetches the layout for the new segment;
/// - real-time Remote Config updates, so publishing in the console changes
///   the home while the app runs.
///
/// The shell composes it: `auth` and `accounts` never know about it.
class PersonalizationCubit extends Cubit<PersonalizationConfig> {
  PersonalizationCubit({
    required this.source,
    required SessionCubit session,
    required this.accounts,
  }) : super(PersonalizationConfig.defaults) {
    _updates = source.updates.listen(_emitIfOpen, onError: _log);
    unawaited(_start(session));
  }

  final PersonalizationSource source;
  final AccountsRepository accounts;

  late final StreamSubscription<PersonalizationConfig> _updates;
  StreamSubscription<SessionState>? _session;
  StreamSubscription<String>? _segment;
  String? _userId;

  Future<void> _start(SessionCubit session) async {
    try {
      await source.initialize();
      _emitIfOpen(source.current);
    } on Object catch (error) {
      // The embedded defaults keep working.
      _log(error);
    }
    if (isClosed) return;
    _onSession(session.state);
    _session = session.stream.listen(_onSession);
  }

  void _onSession(SessionState state) {
    final userId = switch (state) {
      SessionAuthenticated(:final user) => user.id,
      _ => null,
    };
    if (userId == _userId) return;
    _userId = userId;
    unawaited(_segment?.cancel());
    _segment = null;
    if (userId == null) {
      unawaited(source.setSegment(null).catchError(_log));
      return;
    }
    _segment = accounts
        .watchSegment(userId)
        .map(
          (result) => result.match((failure) {
            // Keep the current segment; the next change retries.
            _log(failure.message);
            return null;
          }, (segment) => segment),
        )
        .where((segment) => segment != null)
        .cast<String>()
        .distinct()
        .listen(_applySegment);
  }

  Future<void> _applySegment(String segment) async {
    await source.setSegment(segment);
    _emitIfOpen(source.current);
  }

  /// Fetches the latest values (pull to refresh).
  Future<void> refresh() async {
    await source.refresh();
    _emitIfOpen(source.current);
  }

  void _emitIfOpen(PersonalizationConfig config) {
    if (!isClosed) emit(config);
  }

  void _log(Object error) => developer.log('$error', name: 'personalization');

  @override
  Future<void> close() async {
    await _updates.cancel();
    await _session?.cancel();
    await _segment?.cancel();
    return super.close();
  }
}
