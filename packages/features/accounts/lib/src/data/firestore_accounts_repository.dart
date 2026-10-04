import 'dart:async';

import 'package:accounts/src/data/firestore_failure_mapper.dart';
import 'package:accounts/src/data/firestore_mappers.dart';
import 'package:accounts/src/data/opening_data.dart';
import 'package:accounts/src/domain/entities/account_transaction.dart';
import 'package:accounts/src/domain/entities/paging.dart';
import 'package:accounts/src/domain/entities/transfer.dart';
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
  /// Segment of a customer nobody has classified yet.
  static const defaultSegment = 'new_user';

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
  Stream<Either<Failure, String>> watchSegment(String userId) {
    return _user(userId)
        .snapshots()
        .map<Either<Failure, String>>(
          (doc) => Right(switch (doc.data()?['segment']) {
            final String segment when segment.isNotEmpty => segment,
            _ => defaultSegment,
          }),
        )
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

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final pageDocs = docs.take(pageSize).toList();
      return TransactionPage(
        items: [
          for (final doc in pageDocs)
            transactionFromFirestore(doc.id, doc.data()),
        ],
        next: docs.length > pageSize ? TransactionCursor(pageDocs.last) : null,
        isFromCache: snapshot.metadata.isFromCache,
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
          'segment': defaultSegment,
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

  // Firestore auto-ids are generated on the device; no document is created.
  @override
  String newTransferId() => _firestore.collection('transfers').doc().id;

  @override
  Future<Either<Failure, TransferReceipt>> transfer({
    required String userId,
    required String transferId,
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required String concept,
  }) {
    return _guard(() async {
      final now = _clock();
      final fromRef = _accounts(userId).doc(fromAccountId);
      final toRef = _accounts(userId).doc(toAccountId);
      // Both movements use the transfer id as their document id.
      final debitRef = fromRef.collection('transactions').doc(transferId);
      final creditRef = toRef.collection('transactions').doc(transferId);

      // All reads first, then all writes: Firestore retries the function if
      // another write touched these accounts meanwhile, so balances are
      // always computed from fresh data.
      return _firestore.runTransaction((transaction) async {
        final fromDoc = await transaction.get(fromRef);
        final toDoc = await transaction.get(toRef);
        final debitDoc = await transaction.get(debitRef);
        // Already applied: Firestore retries a transaction whose commit
        // response was lost, and the user may retry after an error. Answer
        // with the original result instead of moving the money again.
        if (debitDoc.exists) {
          final debit = transactionFromFirestore(debitDoc.id, debitDoc.data()!);
          return TransferReceipt(
            transferId: transferId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            amountCents: debit.amountCents,
            concept: concept,
            createdAt: debit.createdAt,
            fromBalanceAfterCents: debit.balanceAfterCents,
          );
        }
        if (!fromDoc.exists || !toDoc.exists) {
          throw const TransferRuleException(TransferError.accountNotFound);
        }
        final from = accountFromFirestore(fromDoc.id, fromDoc.data()!);
        final to = accountFromFirestore(toDoc.id, toDoc.data()!);
        if (from.balanceCents < amountCents) {
          throw const TransferRuleException(TransferError.insufficientFunds);
        }

        final fromBalance = from.balanceCents - amountCents;
        final toBalance = to.balanceCents + amountCents;

        transaction
          ..update(fromRef, {
            'balanceCents': fromBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          ..update(toRef, {
            'balanceCents': toBalance,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          ..set(debitRef, {
            ...transactionToFirestore(
              AccountTransaction(
                id: debitRef.id,
                type: TransactionType.debit,
                amountCents: amountCents,
                description: concept.isEmpty
                    ? 'Transferencia a ${to.alias}'
                    : concept,
                category: 'transfer',
                createdAt: now,
                balanceAfterCents: fromBalance,
              ),
              source: 'transfer',
            ),
            'transferId': transferId,
          })
          ..set(creditRef, {
            ...transactionToFirestore(
              AccountTransaction(
                id: creditRef.id,
                type: TransactionType.credit,
                amountCents: amountCents,
                description: concept.isEmpty
                    ? 'Transferencia desde ${from.alias}'
                    : concept,
                category: 'transfer',
                createdAt: now,
                balanceAfterCents: toBalance,
              ),
              source: 'transfer',
            ),
            'transferId': transferId,
          });

        return TransferReceipt(
          transferId: transferId,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amountCents: amountCents,
          concept: concept,
          createdAt: now,
          fromBalanceAfterCents: fromBalance,
        );
      });
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
