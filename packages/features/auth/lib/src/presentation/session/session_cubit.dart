import 'dart:async';

import 'package:auth/src/domain/entities/app_user.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether there is a signed-in user. The router uses it to redirect.
sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

/// Startup: Firebase has not reported the stored session yet.
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// Mirrors [AuthRepository.userChanges] for the whole app.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository) : super(const SessionUnknown()) {
    _subscription = _repository.userChanges().listen(
      (user) => emit(
        user == null
            ? const SessionUnauthenticated()
            : SessionAuthenticated(user),
      ),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  /// The new state arrives through [AuthRepository.userChanges].
  Future<void> signOut() => _repository.signOut();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
