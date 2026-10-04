/// Accounts feature: accounts, balances, movements and transfers.
///
/// Depends only on `core`, `design_system` and `sdui`; the app shell composes
/// it (routes and dependencies).
library;

export 'l10n/gen/accounts_localizations.dart';
export 'src/data/firestore_accounts_repository.dart';
export 'src/domain/entities/account.dart';
export 'src/domain/entities/account_transaction.dart';
export 'src/domain/entities/paging.dart';
export 'src/domain/entities/transfer.dart';
export 'src/domain/repositories/accounts_repository.dart';
export 'src/domain/usecases/transfer_between_own_accounts.dart';
export 'src/presentation/pages/account_detail_page.dart';
export 'src/presentation/pages/accounts_page.dart';
export 'src/presentation/pages/transfer_page.dart';
export 'src/presentation/sdui/accounts_sdui_components.dart';
