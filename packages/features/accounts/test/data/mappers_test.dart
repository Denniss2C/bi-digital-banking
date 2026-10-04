import 'package:accounts/accounts.dart';
import 'package:accounts/src/data/firestore_failure_mapper.dart';
import 'package:accounts/src/data/firestore_mappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('accountFromFirestore', () {
    test('reads a valid document', () {
      final account = accountFromFirestore('savings', {
        'type': 'savings',
        'alias': 'Cuenta de Ahorros',
        'maskedNumber': '•••• 4892',
        'balanceCents': 384550,
        'currency': 'USD',
      });

      expect(
        account,
        const Account(
          id: 'savings',
          type: AccountType.savings,
          alias: 'Cuenta de Ahorros',
          maskedNumber: '•••• 4892',
          balanceCents: 384550,
        ),
      );
    });

    test('rejects malformed documents with a FormatException', () {
      expect(
        () => accountFromFirestore('x', {'type': 'credit-card'}),
        throwsFormatException,
      );
      expect(
        () => accountFromFirestore('x', {
          'type': 'savings',
          'alias': 'A',
          'maskedNumber': '1',
          'balanceCents': 'lots',
        }),
        throwsFormatException,
      );
    });
  });

  group('transactions', () {
    final transaction = AccountTransaction(
      id: 't1',
      type: TransactionType.debit,
      amountCents: 6430,
      description: 'Supermaxi',
      category: 'groceries',
      createdAt: DateTime(2026, 10, 1, 11, 30),
      balanceAfterCents: 378120,
    );

    test('round-trips through a Firestore map', () {
      final data = transactionToFirestore(transaction, source: 'seed');

      expect(data['source'], 'seed');
      expect(transactionFromFirestore('t1', data), transaction);
      expect(transaction.signedAmountCents, -6430);
    });

    test('a missing timestamp is a FormatException', () {
      final data = transactionToFirestore(transaction, source: 'seed')
        ..remove('createdAt');

      expect(() => transactionFromFirestore('t1', data), throwsFormatException);
    });
  });

  group('mapFirestoreError', () {
    FirebaseException error(String code) =>
        FirebaseException(plugin: 'cloud_firestore', code: code);

    test('maps connectivity, permission and other errors', () {
      expect(mapFirestoreError(error('unavailable')), isA<NetworkFailure>());
      expect(
        mapFirestoreError(error('deadline-exceeded')),
        isA<NetworkFailure>(),
      );
      expect(mapFirestoreError(error('permission-denied')), isA<AuthFailure>());
      expect(mapFirestoreError(error('internal')), isA<ServerFailure>());
      expect(
        mapFirestoreError(const FormatException('bad')),
        isA<ServerFailure>(),
      );
    });
  });
}
