import 'dart:async';

import 'package:accounts/src/domain/entities/account.dart';
import 'package:accounts/src/domain/entities/paging.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

sealed class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => [];
}

final class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

/// Accounts on screen. An empty list means the opening data is still being
/// prepared; [isFromCache] means the data comes from the offline cache.
final class AccountsLoaded extends AccountsState {
  const AccountsLoaded({required this.accounts, required this.isFromCache});

  final List<Account> accounts;
  final bool isFromCache;

  int get totalCents =>
      accounts.fold(0, (total, account) => total + account.balanceCents);

  @override
  List<Object?> get props => [accounts, isFromCache];
}

final class AccountsError extends AccountsState {
  const AccountsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Live accounts of the signed-in customer.
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit({required this.repository, required this.userId})
    : super(const AccountsLoading()) {
    _subscribe();
  }

  final AccountsRepository repository;
  final String userId;
  StreamSubscription<Either<Failure, AccountsSnapshot>>? _subscription;

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = repository
        .watchAccounts(userId)
        .listen(
          (result) => emit(
            result.match(
              AccountsError.new,
              (snapshot) => AccountsLoaded(
                accounts: snapshot.accounts,
                isFromCache: snapshot.isFromCache,
              ),
            ),
          ),
        );
  }

  /// Subscribes again after an error.
  void retry() {
    emit(const AccountsLoading());
    _subscribe();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
