import 'dart:async';

import 'package:accounts/src/data/firestore_failure_mapper.dart';
import 'package:accounts/src/data/firestore_mappers.dart';
import 'package:accounts/src/data/opening_data.dart';
import 'package:accounts/src/domain/entities/paging.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// [AccountsRepository] on Cloud Firestore:
///
/// ```text
/// users/{uid}                                     profile
/// users/{uid}/accounts/{accountId}                account
/// users/{uid}/accounts/{accountId}/transactions   movements (ledger)
/// ```
class FirestoreAccountsRepository implements AccountsRepository {
  FirestoreAccountsRepository(this._firestore, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Default Firestore instance with offline persistence explicitly enabled:
  /// the last known data stays readable without connectivity.
  factory FirestoreAccountsRepository.instance() {
    final firestore = FirebaseFirestore.instance
      ..settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    return FirestoreAccountsRepository(firestore);
  }

  final FirebaseFirestore _firestore;
  final DateTime Function() _clock;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _accounts(String userId) =>
      _user(userId).collection('accounts');

  @override
  Stream<Either<Failure, AccountsSnapshot>> watchAccounts(String userId) {
    return _accounts(userId)
        // Metadata changes re-emit when data moves from cache to server.
        .snapshots(includeMetadataChanges: true)
        .map<Either<Failure, AccountsSnapshot>>((snapshot) {
          final accounts =
              snapshot.docs
                  .map((doc) => accountFromFirestore(doc.id, doc.data()))
                  .toList()
                // Savings first, then checking (AccountType order).
                ..sort((a, b) => a.type.index.compareTo(b.type.index));
          return Right(
            AccountsSnapshot(
              accounts: accounts,
              isFromCache: snapshot.metadata.isFromCache,
            ),
          );
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.add(Left(mapFirestoreError(error))),
          ),
        );
  }

  @override
  Future<Either<Failure, TransactionPage>> fetchTransactions({
    required String userId,
    required String accountId,
    TransactionCursor? after,
    int pageSize = 20,
  }) {
    return _guard(() async {
      // Conventional order: orderBy → startAfter → limit. Firestore itself is
      // declarative, but fake_cloud_firestore applies them in call order.
      var query = _accounts(userId)
          .doc(accountId)
          .collection('transactions')
          .orderBy('createdAt', descending: true);
      final last = after?.value;
      if (last is DocumentSnapshot) query = query.startAfterDocument(last);
      // One extra document tells whether another page exists.
      query = query.limit(pageSize + 1);

      final docs = (await query.get()).docs;
      final pageDocs = docs.take(pageSize).toList();
      return TransactionPage(
        items: [
          for (final doc in pageDocs)
            transactionFromFirestore(doc.id, doc.data()),
        ],
        next: docs.length > pageSize ? TransactionCursor(pageDocs.last) : null,
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> ensureOpeningData({
    required String userId,
    required String name,
    required String email,
  }) {
    return _guard(() async {
      final userRef = _user(userId);
      // A transaction makes the check-then-write atomic, so two devices
      // signing in at the same time cannot create the data twice.
      await _firestore.runTransaction((transaction) async {
        final profile = await transaction.get(userRef);
        if (profile.data()?['openingDataAt'] != null) {
          // Already opened. On sign-up the display name arrives in a second
          // auth event, so keep the profile name up to date.
          if (name.isNotEmpty && profile.data()?['name'] != name) {
            transaction.update(userRef, {'name': name});
          }
          return;
        }

        transaction.set(userRef, {
          'name': name,
          'email': email,
          'segment': 'new_user',
          'onboardingCompleted': true,
          'preferences': <String, dynamic>{},
          'fcmTokens': <String>[],
          'openingDataAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        for (final opening in buildOpeningData(_clock())) {
          final accountRef = _accounts(userId).doc(opening.account.id);
          transaction.set(accountRef, accountToFirestore(opening.account));
          for (final movement in opening.transactions) {
            transaction.set(
              accountRef.collection('transactions').doc(movement.id),
              transactionToFirestore(movement, source: 'seed'),
            );
          }
        }
      });
      return unit;
    });
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on Object catch (error) {
      return Left(mapFirestoreError(error));
    }
  }
}
