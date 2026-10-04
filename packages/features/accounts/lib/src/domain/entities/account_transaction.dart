import 'package:equatable/equatable.dart';

enum TransactionType { credit, debit }

/// A movement of an account. Immutable once written (ledger).
class AccountTransaction extends Equatable {
  const AccountTransaction({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.balanceAfterCents,
  });

  final String id;
  final TransactionType type;

  /// Always positive; [type] tells the direction.
  final int amountCents;
  final String description;

  /// e.g. `salary`, `groceries`, `transfer` (used for icons and filters).
  final String category;
  final DateTime createdAt;
  final int balanceAfterCents;

  /// Positive for credits, negative for debits.
  int get signedAmountCents =>
      type == TransactionType.credit ? amountCents : -amountCents;

  @override
  List<Object?> get props => [
    id,
    type,
    amountCents,
    description,
    category,
    createdAt,
    balanceAfterCents,
  ];
}
