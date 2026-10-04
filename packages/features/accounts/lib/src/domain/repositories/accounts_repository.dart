import 'package:accounts/src/domain/entities/paging.dart';
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

  /// Creates the profile and the opening accounts the first time a customer
  /// signs in. Safe to call on every sign-in: it does nothing afterwards.
  Future<Either<Failure, Unit>> ensureOpeningData({
    required String userId,
    required String name,
    required String email,
  });
}
