import 'package:accounts/accounts.dart';
import 'package:core/core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const uid = 'uid-1';
  late FakeFirebaseFirestore firestore;
  late FirestoreAccountsRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
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
}
