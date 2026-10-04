import 'package:accounts/accounts.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAccountsRepository repository;
  late TransferBetweenOwnAccounts transfer;

  final receipt = TransferReceipt(
    transferId: 'tx-1',
    fromAccountId: 'savings',
    toAccountId: 'checking',
    amountCents: 5000,
    concept: 'Ahorro',
    createdAt: DateTime(2026, 10, 3),
    fromBalanceAfterCents: 379550,
  );

  setUp(() {
    repository = MockAccountsRepository();
    transfer = TransferBetweenOwnAccounts(repository);
  });

  group('validate', () {
    TransferError? validate({
      String from = 'savings',
      String to = 'checking',
      int amountCents = 5000,
      String concept = '',
    }) => TransferBetweenOwnAccounts.validate(
      fromAccountId: from,
      toAccountId: to,
      amountCents: amountCents,
      concept: concept,
    );

    test('accepts a valid transfer, up to the limit', () {
      expect(validate(), isNull);
      expect(validate(amountCents: 1), isNull);
      expect(validate(amountCents: 500000), isNull);
      expect(validate(concept: 'a' * 60), isNull);
    });

    test('rejects the same account as origin and destination', () {
      expect(validate(to: 'savings'), TransferError.sameAccount);
    });

    test('rejects zero and negative amounts', () {
      expect(validate(amountCents: 0), TransferError.invalidAmount);
      expect(validate(amountCents: -100), TransferError.invalidAmount);
    });

    test(r'rejects more than $5,000.00 per transfer', () {
      expect(validate(amountCents: 500001), TransferError.limitExceeded);
    });

    test('rejects a long concept, ignoring surrounding spaces', () {
      expect(validate(concept: 'a' * 61), TransferError.conceptTooLong);
      expect(validate(concept: '  ${'a' * 60}  '), isNull);
    });
  });

  group('call', () {
    test('a broken rule fails without calling the repository', () async {
      final result = await transfer(
        userId: 'u',
        transferId: 'tx-1',
        fromAccountId: 'savings',
        toAccountId: 'savings',
        amountCents: 5000,
      );

      expect(
        result,
        const Left<Failure, TransferReceipt>(
          ValidationFailure(code: 'sameAccount'),
        ),
      );
      verifyZeroInteractions(repository);
    });

    test(
      'a valid transfer reaches the repository with a trimmed concept',
      () async {
        when(
          () => repository.transfer(
            userId: any(named: 'userId'),
            transferId: any(named: 'transferId'),
            fromAccountId: any(named: 'fromAccountId'),
            toAccountId: any(named: 'toAccountId'),
            amountCents: any(named: 'amountCents'),
            concept: any(named: 'concept'),
          ),
        ).thenAnswer((_) async => Right(receipt));

        final result = await transfer(
          userId: 'u',
          transferId: 'tx-1',
          fromAccountId: 'savings',
          toAccountId: 'checking',
          amountCents: 5000,
          concept: '  Ahorro ',
        );

        expect(result, Right<Failure, TransferReceipt>(receipt));
        verify(
          () => repository.transfer(
            userId: 'u',
            transferId: 'tx-1',
            fromAccountId: 'savings',
            toAccountId: 'checking',
            amountCents: 5000,
            concept: 'Ahorro',
          ),
        ).called(1);
      },
    );
  });
}
