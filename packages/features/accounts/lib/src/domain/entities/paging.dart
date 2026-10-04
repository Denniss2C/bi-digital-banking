import 'package:accounts/src/domain/entities/account.dart';
import 'package:accounts/src/domain/entities/account_transaction.dart';
import 'package:equatable/equatable.dart';

/// Opaque position in a list of transactions. The data layer decides what it
/// holds, so the domain never depends on Firestore types.
class TransactionCursor {
  const TransactionCursor(this.value);

  final Object value;
}

/// One page of transactions, newest first.
class TransactionPage extends Equatable {
  const TransactionPage({required this.items, this.next});

  final List<AccountTransaction> items;

  /// Cursor for the following page; `null` when there are no more.
  final TransactionCursor? next;

  bool get hasMore => next != null;

  @override
  List<Object?> get props => [items, hasMore];
}

/// Accounts plus where they came from: `isFromCache` is true while offline
/// (or before the server answers), so the UI can warn that data may be stale.
class AccountsSnapshot extends Equatable {
  const AccountsSnapshot({required this.accounts, required this.isFromCache});

  final List<Account> accounts;
  final bool isFromCache;

  @override
  List<Object?> get props => [accounts, isFromCache];
}
