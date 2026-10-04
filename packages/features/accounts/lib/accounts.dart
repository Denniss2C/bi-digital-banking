/// Accounts feature: accounts, balances, movements and transfers.
///
/// Depends only on `core`, `design_system` and `sdui`; the app shell composes
/// it (routes and dependencies).
library;

export 'src/data/firestore_accounts_repository.dart';
export 'src/domain/entities/account.dart';
export 'src/domain/entities/account_transaction.dart';
export 'src/domain/entities/paging.dart';
export 'src/domain/repositories/accounts_repository.dart';
