import 'package:accounts/src/domain/entities/account.dart';
import 'package:accounts/src/domain/entities/account_transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore documents are untrusted input: a malformed document throws a
// FormatException (mapped to a ServerFailure) instead of a raw TypeError.

Account accountFromFirestore(String id, Map<String, dynamic> data) {
  return Account(
    id: id,
    type: switch (data['type']) {
      'savings' => AccountType.savings,
      'checking' => AccountType.checking,
      final other => throw FormatException('Unknown account type: $other'),
    },
    alias: _string(data, 'alias'),
    maskedNumber: _string(data, 'maskedNumber'),
    balanceCents: _int(data, 'balanceCents'),
    currency: data['currency'] as String? ?? 'USD',
  );
}

Map<String, dynamic> accountToFirestore(Account account) => {
  'type': account.type.name,
  'alias': account.alias,
  'maskedNumber': account.maskedNumber,
  'balanceCents': account.balanceCents,
  'currency': account.currency,
  'updatedAt': FieldValue.serverTimestamp(),
};

AccountTransaction transactionFromFirestore(
  String id,
  Map<String, dynamic> data,
) {
  final createdAt = data['createdAt'];
  if (createdAt is! Timestamp) {
    throw FormatException('Transaction $id has no createdAt timestamp');
  }
  return AccountTransaction(
    id: id,
    type: switch (data['type']) {
      'credit' => TransactionType.credit,
      'debit' => TransactionType.debit,
      final other => throw FormatException('Unknown transaction type: $other'),
    },
    amountCents: _int(data, 'amountCents'),
    description: _string(data, 'description'),
    category: data['category'] as String? ?? 'other',
    createdAt: createdAt.toDate(),
    balanceAfterCents: _int(data, 'balanceAfterCents'),
  );
}

/// [source] tells real operations (`transfer`) apart from opening data
/// (`seed`).
Map<String, dynamic> transactionToFirestore(
  AccountTransaction transaction, {
  required String source,
}) => {
  'type': transaction.type.name,
  'amountCents': transaction.amountCents,
  'description': transaction.description,
  'category': transaction.category,
  'createdAt': Timestamp.fromDate(transaction.createdAt),
  'balanceAfterCents': transaction.balanceAfterCents,
  'source': source,
};

int _int(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is num) return value.toInt();
  throw FormatException('Field "$key" must be a number, got $value');
}

String _string(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String) return value;
  throw FormatException('Field "$key" must be a string, got $value');
}
