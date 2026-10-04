import 'package:equatable/equatable.dart';

enum AccountType { savings, checking }

/// A customer's bank account. Money is in integer cents (never `double`).
class Account extends Equatable {
  const Account({
    required this.id,
    required this.type,
    required this.alias,
    required this.maskedNumber,
    required this.balanceCents,
    this.currency = 'USD',
  });

  final String id;
  final AccountType type;
  final String alias;

  /// Last digits only, e.g. "•••• 4892".
  final String maskedNumber;
  final int balanceCents;
  final String currency;

  @override
  List<Object?> get props => [
    id,
    type,
    alias,
    maskedNumber,
    balanceCents,
    currency,
  ];
}
