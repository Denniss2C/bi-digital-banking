import 'package:accounts/src/domain/entities/account_transaction.dart';
import 'package:accounts/src/domain/entities/paging.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

enum TransactionsStatus { loading, success, failure }

final class TransactionsState extends Equatable {
  const TransactionsState({
    this.status = TransactionsStatus.loading,
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isFromCache = false,
    this.failure,
  });

  final TransactionsStatus status;
  final List<AccountTransaction> items;
  final bool hasMore;
  final bool isLoadingMore;

  /// Loading the next page failed; the loaded items stay on screen.
  final bool loadMoreFailed;
  final bool isFromCache;

  /// Why the first page failed (status `failure`).
  final Failure? failure;

  TransactionsState copyWith({
    List<AccountTransaction>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? isFromCache,
  }) {
    return TransactionsState(
      status: status,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      isFromCache: isFromCache ?? this.isFromCache,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    hasMore,
    isLoadingMore,
    loadMoreFailed,
    isFromCache,
    failure,
  ];
}

/// Paginated movements of one account (infinite scroll).
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit({
    required this.repository,
    required this.userId,
    required this.accountId,
    this.pageSize = 20,
  }) : super(const TransactionsState());

  final AccountsRepository repository;
  final String userId;
  final String accountId;
  final int pageSize;
  TransactionCursor? _next;

  /// Loads (or reloads after an error) the first page.
  Future<void> load() async {
    emit(const TransactionsState());
    final result = await _fetch(after: null);
    // The user may leave the detail while the page is loading.
    if (isClosed) return;
    emit(
      result.match(
        (failure) => TransactionsState(
          status: TransactionsStatus.failure,
          failure: failure,
        ),
        (page) {
          _next = page.next;
          return TransactionsState(
            status: TransactionsStatus.success,
            items: page.items,
            hasMore: page.hasMore,
            isFromCache: page.isFromCache,
          );
        },
      ),
    );
  }

  /// Appends the next page. Ignored while loading or when there is no more.
  Future<void> loadMore() async {
    if (state.status != TransactionsStatus.success ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final result = await _fetch(after: _next);
    if (isClosed) return;
    emit(
      result.match(
        (_) => state.copyWith(isLoadingMore: false, loadMoreFailed: true),
        (page) {
          _next = page.next;
          return state.copyWith(
            items: [...state.items, ...page.items],
            hasMore: page.hasMore,
            isLoadingMore: false,
            isFromCache: state.isFromCache || page.isFromCache,
          );
        },
      ),
    );
  }

  Future<Either<Failure, TransactionPage>> _fetch({
    required TransactionCursor? after,
  }) => repository.fetchTransactions(
    userId: userId,
    accountId: accountId,
    after: after,
    pageSize: pageSize,
  );
}
