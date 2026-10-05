import 'package:accounts/accounts.dart';
import 'package:core/core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../helpers/opening_template.dart';

void main() {
  const uid = 'uid-1';
  late FakeFirebaseFirestore firestore;
  late FirestoreAccountsRepository repository;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    // Published with `make deploy-opening`.
    await firestore.doc(OpeningTemplate.path).set(openingTemplateJson());
    repository = FirestoreAccountsRepository(
      firestore,
      clock: () => DateTime(2026, 10, 3, 18),
    );
  });

  Future<void> open() async {
    final result = await repository.ensureOpeningData(
      userId: uid,
      name: 'Mateo Moreno',
      email: 'mateo@nexo.ec',
    );
    expect(result.isRight(), isTrue);
  }

  group('ensureOpeningData', () {
    test('creates the profile, two accounts and their movements', () async {
      await open();

      final profile = await firestore.doc('users/$uid').get();
      expect(profile.data()?['email'], 'mateo@nexo.ec');
      expect(profile.data()?['segment'], 'new_user');

      final accounts = await firestore.collection('users/$uid/accounts').get();
      expect(
        accounts.docs.map((d) => d.id),
        containsAll(['savings', 'checking']),
      );

      final movements = await firestore
          .collection('users/$uid/accounts/savings/transactions')
          .get();
      expect(movements.docs, hasLength(24));
      expect(movements.docs.first.data()['source'], 'seed');
    });

    test('takes the accounts from the template in Firestore', () async {
      await firestore.doc(OpeningTemplate.path).set({
        'schemaVersion': 1,
        'accounts': [
          {
            'id': 'savings',
            'type': 'savings',
            'alias': 'Ahorro Meta',
            'maskedNumber': '•••• 0001',
            'movements': [
              {
                'daysAgo': 2,
                'amountCents': 10000,
                'description': 'Depósito de apertura',
                'category': 'deposit',
              },
            ],
          },
        ],
      });

      await open();

      final accounts = await firestore.collection('users/$uid/accounts').get();
      expect(accounts.docs.single.data()['alias'], 'Ahorro Meta');
      expect(accounts.docs.single.data()['balanceCents'], 10000);
    });

    test('without a template it writes nothing and fails', () async {
      await firestore.doc(OpeningTemplate.path).delete();

      final result = await repository.ensureOpeningData(
        userId: uid,
        name: 'Mateo Moreno',
        email: 'mateo@nexo.ec',
      );

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect((await firestore.doc('users/$uid').get()).exists, isFalse);
    });

    test('with an invalid template it writes nothing and fails', () async {
      await firestore.doc(OpeningTemplate.path).set({'accounts': <Object>[]});

      final result = await repository.ensureOpeningData(
        userId: uid,
        name: 'Mateo Moreno',
        email: 'mateo@nexo.ec',
      );

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect((await firestore.doc('users/$uid').get()).exists, isFalse);
    });

    test('an opened customer does not need the template', () async {
      await open();
      await firestore.doc(OpeningTemplate.path).delete();

      final result = await repository.ensureOpeningData(
        userId: uid,
        name: 'Mateo Moreno',
        email: 'mateo@nexo.ec',
      );

      expect(result.isRight(), isTrue);
    });

    test('is idempotent: a second sign-in changes nothing', () async {
      await open();
      // Simulate later activity on the account.
      await firestore.doc('users/$uid/accounts/savings').update({
        'balanceCents': 1,
      });

      await open();

      final savings = await firestore.doc('users/$uid/accounts/savings').get();
      expect(savings.data()?['balanceCents'], 1);
      final movements = await firestore
          .collection('users/$uid/accounts/savings/transactions')
          .get();
      expect(movements.docs, hasLength(24));
    });
  });

  test('a later sign-in with the display name updates the profile', () async {
    await repository.ensureOpeningData(
      userId: uid,
      name: '',
      email: 'm@nexo.ec',
    );
    await repository.ensureOpeningData(
      userId: uid,
      name: 'Mateo Moreno',
      email: 'm@nexo.ec',
    );

    final profile = await firestore.doc('users/$uid').get();
    expect(profile.data()?['name'], 'Mateo Moreno');
  });

  group('watchAccounts', () {
    test('emits the accounts, savings first', () async {
      await open();

      final first = await repository.watchAccounts(uid).first;

      final snapshot = first.getRight().toNullable()!;
      expect(snapshot.accounts.map((a) => a.type), [
        AccountType.savings,
        AccountType.checking,
      ]);
      expect(snapshot.accounts.first.balanceCents, greaterThan(0));
    });

    test('a malformed document becomes a Left, not a stream error', () async {
      await firestore.doc('users/$uid/accounts/broken').set({'type': 'other'});

      final first = await repository.watchAccounts(uid).first;

      expect(first.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('watchSegment', () {
    test('a new customer is new_user', () async {
      await open();

      final first = await repository.watchSegment(uid).first;

      expect(first, const Right<Failure, String>('new_user'));
    });

    test('follows changes to the segment', () async {
      await open();
      final segments = repository
          .watchSegment(uid)
          .map((result) => result.getRight().toNullable())
          .take(2)
          .toList();

      await firestore.doc('users/$uid').update({'segment': 'saver'});

      expect(await segments, ['new_user', 'saver']);
    });

    test('setSegment changes it and keeps the rest of the profile', () async {
      await open();

      final result = await repository.setSegment(userId: uid, segment: 'saver');

      expect(result.isRight(), isTrue);
      expect(
        await repository.watchSegment(uid).first,
        const Right<Failure, String>('saver'),
      );
      final profile = await firestore.doc('users/$uid').get();
      expect(profile.data()?['email'], 'mateo@nexo.ec');
    });

    test('without a profile yet it is new_user', () async {
      final first = await repository.watchSegment(uid).first;

      expect(first, const Right<Failure, String>('new_user'));
    });
  });

  group('fetchTransactions', () {
    test('pages newest first without overlaps', () async {
      await open();

      final page1 = (await repository.fetchTransactions(
        userId: uid,
        accountId: 'savings',
      )).getRight().toNullable()!;
      final page2 = (await repository.fetchTransactions(
        userId: uid,
        accountId: 'savings',
        after: page1.next,
      )).getRight().toNullable()!;

      expect(page1.items, hasLength(20));
      expect(page1.hasMore, isTrue);
      expect(page2.items, hasLength(4));
      expect(page2.hasMore, isFalse);

      final all = [...page1.items, ...page2.items];
      expect(all.map((t) => t.id).toSet(), hasLength(24));
      final dates = all.map((t) => t.createdAt).toList();
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));
    });
  });

  group('transfer', () {
    Future<int> balance(String accountId) async {
      final doc = await firestore.doc('users/$uid/accounts/$accountId').get();
      return doc.data()!['balanceCents'] as int;
    }

    Future<List<Map<String, dynamic>>> transferMovements(
      String accountId,
    ) async {
      final query = await firestore
          .collection('users/$uid/accounts/$accountId/transactions')
          .where('source', isEqualTo: 'transfer')
          .get();
      return query.docs.map((doc) => doc.data()).toList();
    }

    Future<Either<Failure, TransferReceipt>> send(
      int amountCents, {
      String to = 'checking',
      String concept = '',
      String? id,
    }) => repository.transfer(
      userId: uid,
      transferId: id ?? repository.newTransferId(),
      fromAccountId: 'savings',
      toAccountId: to,
      amountCents: amountCents,
      concept: concept,
    );

    test('moves the money and records one movement on each side', () async {
      await open();
      final savingsBefore = await balance('savings');
      final checkingBefore = await balance('checking');

      final receipt = (await send(12550)).getRight().toNullable()!;

      expect(await balance('savings'), savingsBefore - 12550);
      expect(await balance('checking'), checkingBefore + 12550);
      expect(receipt.fromBalanceAfterCents, savingsBefore - 12550);
      expect(receipt.createdAt, DateTime(2026, 10, 3, 18));

      final debit = (await transferMovements('savings')).single;
      final credit = (await transferMovements('checking')).single;
      expect(debit['type'], 'debit');
      expect(credit['type'], 'credit');
      expect([debit['amountCents'], credit['amountCents']], [12550, 12550]);
      expect(debit['transferId'], receipt.transferId);
      expect(credit['transferId'], receipt.transferId);
      final debitDoc = firestore.doc(
        'users/$uid/accounts/savings/transactions/${receipt.transferId}',
      );
      expect((await debitDoc.get()).exists, isTrue);
      expect(debit['balanceAfterCents'], savingsBefore - 12550);
      expect(credit['balanceAfterCents'], checkingBefore + 12550);
      expect(debit['description'], 'Transferencia a Cuenta Corriente');
      expect(credit['description'], 'Transferencia desde Cuenta de Ahorros');
    });

    test('repeating a transfer id moves the money only once', () async {
      await open();
      final savingsBefore = await balance('savings');
      final checkingBefore = await balance('checking');
      final id = repository.newTransferId();

      final first = await send(1000, id: id);
      final retry = await send(1000, id: id);

      expect(retry, first);
      expect(await balance('savings'), savingsBefore - 1000);
      expect(await balance('checking'), checkingBefore + 1000);
      expect(await transferMovements('savings'), hasLength(1));
      expect(await transferMovements('checking'), hasLength(1));
    });

    test('the concept describes both movements', () async {
      await open();

      await send(1000, concept: 'Ahorro viaje');

      for (final account in ['savings', 'checking']) {
        final movement = (await transferMovements(account)).single;
        expect(movement['description'], 'Ahorro viaje', reason: account);
      }
    });

    test('the movement is the newest one in the history', () async {
      await open();

      await send(1000);

      final page = (await repository.fetchTransactions(
        userId: uid,
        accountId: 'checking',
      )).getRight().toNullable()!;
      expect(page.items.first.category, 'transfer');
      expect(page.items.first.type, TransactionType.credit);
    });

    test('the whole balance can be sent, but not one cent more', () async {
      await open();
      final all = await balance('savings');

      final tooMuch = await send(all + 1);

      expect(
        tooMuch.getLeft().toNullable(),
        const ValidationFailure(code: 'insufficientFunds'),
      );
      expect(await balance('savings'), all);
      expect(await transferMovements('savings'), isEmpty);
      expect(await transferMovements('checking'), isEmpty);

      expect((await send(all)).isRight(), isTrue);
      expect(await balance('savings'), 0);
    });

    test('an unknown account fails without writing anything', () async {
      await open();
      final before = await balance('savings');

      final result = await send(1000, to: 'missing');

      expect(
        result.getLeft().toNullable(),
        const ValidationFailure(code: 'accountNotFound'),
      );
      expect(await balance('savings'), before);
      expect(await transferMovements('savings'), isEmpty);
    });
  });
}
