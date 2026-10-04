import 'dart:async';

import 'package:accounts/src/domain/entities/account.dart';
import 'package:accounts/src/domain/entities/account_transaction.dart';
import 'package:accounts/src/domain/entities/paging.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

sealed class RecentMovementsState extends Equatable {
  const RecentMovementsState();

  @override
  List<Object?> get props => [];
}

final class RecentMovementsLoading extends RecentMovementsState {
  const RecentMovementsLoading();
}

/// The newest movements of all the accounts, newest first. An empty list
/// means there are no movements yet.
final class RecentMovementsLoaded extends RecentMovementsState {
  const RecentMovementsLoaded({required this.items, required this.isFromCache});

  final List<AccountTransaction> items;
  final bool isFromCache;

  @override
  List<Object?> get props => [items, isFromCache];
}

final class RecentMovementsError extends RecentMovementsState {
  const RecentMovementsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Latest [limit] movements across all the customer's accounts (home).
///
/// It follows the live accounts and fetches again only when a balance
/// changes (e.g. after a transfer), so the list stays current without
/// polling.
class RecentMovementsCubit extends Cubit<RecentMovementsState> {
  RecentMovementsCubit({
    required this.repository,
    required this.userId,
    required this.limit,
  }) : super(const RecentMovementsLoading()) {
    _subscribe();
  }

  final AccountsRepository repository;
  final String userId;
  final int limit;

  StreamSubscription<Either<Failure, AccountsSnapshot>>? _subscription;

  /// Balances already loaded: an equal snapshot (e.g. a metadata-only
  /// update) does not fetch again.
  String? _loadedBalances;

  /// Ignores answers from an older fetch that finishes after a newer one.
  var _request = 0;

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = repository.watchAccounts(userId).listen(_onAccounts);
  }

  void _onAccounts(Either<Failure, AccountsSnapshot> result) {
    result.match(
      (failure) {
        // Keep showing movements already loaded; fail only on first load.
        if (state is! RecentMovementsLoaded) {
          emit(RecentMovementsError(failure));
        }
      },
      (snapshot) {
        final balances = [
          for (final account in snapshot.accounts)
            '${account.id}:${account.balanceCents}',
        ].join(',');
        if (balances == _loadedBalances) return;
        _loadedBalances = balances;
        unawaited(_load(snapshot.accounts));
      },
    );
  }

  Future<void> _load(List<Account> accounts) async {
    final request = ++_request;
    final pages = await Future.wait([
      for (final account in accounts)
        repository.fetchTransactions(
          userId: userId,
          accountId: account.id,
          pageSize: limit,
        ),
    ]);
    if (isClosed || request != _request) return;

    final failure = pages
        .map((page) => page.getLeft().toNullable())
        .nonNulls
        .firstOrNull;
    if (failure != null) {
      // Let a retry or the next balance change fetch again.
      _loadedBalances = null;
      return emit(RecentMovementsError(failure));
    }
    final loaded = [for (final page in pages) page.getRight().toNullable()!];
    // Ids are unique per account only (a transfer's debit and credit share
    // it), so movements are merged by date, never by id.
    final items = [for (final page in loaded) ...page.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(
      RecentMovementsLoaded(
        items: items.take(limit).toList(),
        isFromCache: loaded.any((page) => page.isFromCache),
      ),
    );
  }

  void retry() {
    _loadedBalances = null;
    emit(const RecentMovementsLoading());
    _subscribe();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
