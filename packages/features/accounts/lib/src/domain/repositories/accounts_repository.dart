import 'package:accounts/src/domain/entities/paging.dart';
import 'package:accounts/src/domain/entities/transfer.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Accounts and movements of the signed-in customer.
abstract interface class AccountsRepository {
  /// Live accounts (savings first). Errors arrive as `Left` values instead of
  /// stream errors, so the UI can show them and keep listening.
  Stream<Either<Failure, AccountsSnapshot>> watchAccounts(String userId);

  /// Movements of one account, newest first, [pageSize] at a time.
  Future<Either<Failure, TransactionPage>> fetchTransactions({
    required String userId,
    required String accountId,
    TransactionCursor? after,
    int pageSize = 20,
  });

  /// Personalization segment of the customer (`new_user` until something
  /// else assigns one, e.g. `saver` or `traveler`). Emits on every change;
  /// errors arrive as `Left` values instead of stream errors.
  Stream<Either<Failure, String>> watchSegment(String userId);

  /// Changes the customer's segment. Dev tooling (debug panel): in
  /// production a server process would assign segments.
  Future<Either<Failure, Unit>> setSegment({
    required String userId,
    required String segment,
  });

  /// Creates the profile and the opening accounts the first time a customer
  /// signs in. Safe to call on every sign-in: it does nothing afterwards.
  Future<Either<Failure, Unit>> ensureOpeningData({
    required String userId,
    required String name,
    required String email,
  });

  /// A new idempotency key for [transfer], generated locally.
  String newTransferId();

  /// Atomically moves [amountCents] between two accounts of [userId]: both
  /// balances change and a debit and a credit movement are written, or
  /// nothing changes. Fails with `ValidationFailure(insufficientFunds)` when
  /// the source balance is not enough, and with a `NetworkFailure` offline
  /// (money movements need the server).
  ///
  /// [transferId] makes it idempotent: sending the same id again returns the
  /// original receipt without moving the money twice, so a retry after an
  /// unclear failure (e.g. a lost response) is always safe.
  Future<Either<Failure, TransferReceipt>> transfer({
    required String userId,
    required String transferId,
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required String concept,
  });
}
