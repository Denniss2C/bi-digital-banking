import 'package:equatable/equatable.dart';

/// Business rules a transfer can break. Travel as `ValidationFailure.code`.
enum TransferError {
  sameAccount,
  invalidAmount,
  limitExceeded,
  conceptTooLong,
  insufficientFunds,
  accountNotFound,
}

/// Proof of a completed transfer between the customer's own accounts.
class TransferReceipt extends Equatable {
  const TransferReceipt({
    required this.transferId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amountCents,
    required this.concept,
    required this.createdAt,
    required this.fromBalanceAfterCents,
  });

  /// Shared by the debit and the credit movements.
  final String transferId;
  final String fromAccountId;
  final String toAccountId;
  final int amountCents;
  final String concept;
  final DateTime createdAt;
  final int fromBalanceAfterCents;

  @override
  List<Object?> get props => [
    transferId,
    fromAccountId,
    toAccountId,
    amountCents,
    concept,
    createdAt,
    fromBalanceAfterCents,
  ];
}
