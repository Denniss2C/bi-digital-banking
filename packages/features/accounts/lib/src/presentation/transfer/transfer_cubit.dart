import 'dart:async';

import 'package:accounts/src/domain/entities/account.dart';
import 'package:accounts/src/domain/entities/paging.dart';
import 'package:accounts/src/domain/entities/transfer.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:accounts/src/domain/usecases/transfer_between_own_accounts.dart';
import 'package:accounts/src/presentation/transfer/amount_input.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

enum TransferStatus { loadingAccounts, editing, submitting, success, failure }

final class TransferState extends Equatable {
  const TransferState({
    this.status = TransferStatus.loadingAccounts,
    this.accounts = const [],
    this.fromId,
    this.toId,
    this.amountText = '',
    this.concept = '',
    this.showErrors = false,
    this.failure,
    this.receipt,
  });

  final TransferStatus status;

  /// Live accounts (balances stay fresh while the form is open).
  final List<Account> accounts;
  final String? fromId;
  final String? toId;
  final String amountText;
  final String concept;

  /// Field errors are shown only after the first submit attempt.
  final bool showErrors;
  final Failure? failure;
  final TransferReceipt? receipt;

  int? get amountCents => parseAmountCents(amountText);

  Account? get from => _byId(fromId);
  Account? get to => _byId(toId);

  /// First broken rule, using the same rules as the use case plus a
  /// client-side balance check (the server checks it again atomically).
  TransferError? get validationError {
    if (from == null || to == null) return TransferError.accountNotFound;
    final cents = amountCents;
    if (cents == null) return TransferError.invalidAmount;
    final rule = TransferBetweenOwnAccounts.validate(
      fromAccountId: from!.id,
      toAccountId: to!.id,
      amountCents: cents,
      concept: concept,
    );
    if (rule != null) return rule;
    if (cents > from!.balanceCents) return TransferError.insufficientFunds;
    return null;
  }

  bool get isSubmitting => status == TransferStatus.submitting;

  Account? _byId(String? id) =>
      accounts.where((account) => account.id == id).firstOrNull;

  TransferState copyWith({
    TransferStatus? status,
    List<Account>? accounts,
    String? fromId,
    String? toId,
    String? amountText,
    String? concept,
    bool? showErrors,
    Failure? failure,
    bool clearFailure = false,
    TransferReceipt? receipt,
  }) {
    return TransferState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      amountText: amountText ?? this.amountText,
      concept: concept ?? this.concept,
      showErrors: showErrors ?? this.showErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      receipt: receipt ?? this.receipt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    accounts,
    fromId,
    toId,
    amountText,
    concept,
    showErrors,
    failure,
    receipt,
  ];
}

/// Transfer form between the customer's own accounts.
class TransferCubit extends Cubit<TransferState> {
  TransferCubit({required this.repository, required this.userId})
    : _transfer = TransferBetweenOwnAccounts(repository),
      super(const TransferState()) {
    _subscription = repository.watchAccounts(userId).listen(_onAccounts);
  }

  final AccountsRepository repository;
  final String userId;
  final TransferBetweenOwnAccounts _transfer;
  late final StreamSubscription<Either<Failure, AccountsSnapshot>>
  _subscription;

  /// Idempotency key of the transfer on screen: kept across retries, so a
  /// retry never moves the money twice, and renewed when anything changes.
  String? _transferId;

  void _onAccounts(Either<Failure, AccountsSnapshot> result) {
    result.match(
      (failure) => emit(
        state.copyWith(status: TransferStatus.failure, failure: failure),
      ),
      (snapshot) {
        final accounts = snapshot.accounts;
        final isFirstLoad = state.status == TransferStatus.loadingAccounts;
        emit(
          state.copyWith(
            accounts: accounts,
            status: isFirstLoad ? TransferStatus.editing : null,
            // Defaults: from the first account to the second one.
            fromId: state.fromId ?? accounts.firstOrNull?.id,
            toId: state.toId ?? (accounts.length > 1 ? accounts[1].id : null),
          ),
        );
      },
    );
  }

  void fromChanged(String accountId) => _edit(fromId: accountId);

  void toChanged(String accountId) => _edit(toId: accountId);

  void amountChanged(String text) => _edit(amountText: text);

  void conceptChanged(String concept) => _edit(concept: concept);

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (state.validationError != null) {
      return emit(state.copyWith(showErrors: true));
    }
    emit(
      state.copyWith(
        status: TransferStatus.submitting,
        showErrors: true,
        clearFailure: true,
      ),
    );
    final result = await _transfer(
      userId: userId,
      transferId: _transferId ??= repository.newTransferId(),
      fromAccountId: state.fromId!,
      toAccountId: state.toId!,
      amountCents: state.amountCents!,
      concept: state.concept,
    );
    // The user may leave the screen while the transfer is in flight.
    if (isClosed) return;
    emit(
      result.match(
        (failure) =>
            state.copyWith(status: TransferStatus.failure, failure: failure),
        (receipt) =>
            state.copyWith(status: TransferStatus.success, receipt: receipt),
      ),
    );
  }

  /// Starts a new transfer, keeping the selected accounts.
  void restart() {
    _transferId = null;
    emit(
      TransferState(
        status: TransferStatus.editing,
        accounts: state.accounts,
        fromId: state.fromId,
        toId: state.toId,
      ),
    );
  }

  /// Any change makes it a different transfer, with a new key.
  void _edit({
    String? fromId,
    String? toId,
    String? amountText,
    String? concept,
  }) {
    _transferId = null;
    emit(
      state.copyWith(
        status: TransferStatus.editing,
        fromId: fromId,
        toId: toId,
        amountText: amountText,
        concept: concept,
        clearFailure: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
