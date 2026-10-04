import 'package:accounts/l10n/gen/accounts_localizations.dart';
import 'package:accounts/src/domain/entities/account.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:accounts/src/presentation/accounts/accounts_cubit.dart';
import 'package:accounts/src/presentation/presentation_helpers.dart';
import 'package:accounts/src/presentation/widgets/account_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Cuentas" tab: total balance and one card per account.
///
/// States: loading, accounts, empty (opening data being prepared), error
/// with retry, and offline (cached accounts plus a notice).
class AccountsPage extends StatelessWidget {
  const AccountsPage({
    required this.repository,
    required this.userId,
    required this.onOpenAccount,
    super.key,
  });

  final AccountsRepository repository;
  final String userId;

  /// The shell decides how to navigate to the account detail.
  final ValueChanged<Account> onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    return BlocProvider(
      create: (_) => AccountsCubit(repository: repository, userId: userId),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.accountsTitle)),
        body: BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, state) => switch (state) {
            AccountsLoading() => AppLoading(
              semanticsLabel: l10n.accountsLoading,
            ),
            AccountsError(:final failure) => AppErrorView(
              title: l10n.accountsErrorTitle,
              message: failureMessage(l10n, failure),
              retryLabel: l10n.retry,
              onRetry: context.read<AccountsCubit>().retry,
            ),
            AccountsLoaded(accounts: []) => AppEmptyView(
              icon: Icons.hourglass_top,
              title: l10n.accountsEmptyTitle,
              message: l10n.accountsEmptyMessage,
            ),
            final AccountsLoaded loaded => _AccountsList(
              state: loaded,
              onOpenAccount: onOpenAccount,
            ),
          },
        ),
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.state, required this.onOpenAccount});

  final AccountsLoaded state;
  final ValueChanged<Account> onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    return Column(
      children: [
        if (state.isFromCache) AppOfflineBanner(message: l10n.offlineNotice),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              BalanceHeroCard(
                label: l10n.totalBalanceLabel,
                totalCents: state.totalCents,
                caption: l10n.accountsCount(state.accounts.length),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final account in state.accounts) ...[
                AccountCard(
                  account: account,
                  onTap: () => onOpenAccount(account),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
