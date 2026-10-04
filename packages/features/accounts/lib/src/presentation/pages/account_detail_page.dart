import 'package:accounts/l10n/gen/accounts_localizations.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:accounts/src/presentation/accounts/accounts_cubit.dart';
import 'package:accounts/src/presentation/presentation_helpers.dart';
import 'package:accounts/src/presentation/transactions/transactions_cubit.dart';
import 'package:accounts/src/presentation/widgets/account_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detail of one account: live balance and paginated movements.
///
/// The balance comes from the live accounts stream, so it stays correct
/// after a transfer; movements load 20 at a time as the user scrolls.
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    required this.repository,
    required this.userId,
    required this.accountId,
    this.now,
    super.key,
  });

  final AccountsRepository repository;
  final String userId;
  final String accountId;

  /// Clock for relative dates ("Hoy", "Ayer"); tests pass a fixed one.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AccountsCubit(repository: repository, userId: userId),
        ),
        BlocProvider(
          create: (_) => TransactionsCubit(
            repository: repository,
            userId: userId,
            accountId: accountId,
          )..load(),
        ),
      ],
      child: _AccountDetailView(accountId: accountId, now: now ?? DateTime.now),
    );
  }
}

class _AccountDetailView extends StatelessWidget {
  const _AccountDetailView({required this.accountId, required this.now});

  final String accountId;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    final accounts = context.watch<AccountsCubit>().state;
    final account = switch (accounts) {
      AccountsLoaded(:final accounts) =>
        accounts.where((a) => a.id == accountId).firstOrNull,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(account?.alias ?? l10n.movementsTitle)),
      body: BlocBuilder<TransactionsCubit, TransactionsState>(
        builder: (context, state) {
          final cubit = context.read<TransactionsCubit>();
          return switch (state.status) {
            TransactionsStatus.loading => AppLoading(
              semanticsLabel: l10n.movementsLoading,
            ),
            TransactionsStatus.failure => AppErrorView(
              title: l10n.movementsErrorTitle,
              message: failureMessage(l10n, state.failure!),
              retryLabel: l10n.retry,
              onRetry: cubit.load,
            ),
            TransactionsStatus.success => _MovementsList(
              state: state,
              header: account == null
                  ? null
                  : BalanceHeroCard(
                      label: l10n.availableBalance,
                      totalCents: account.balanceCents,
                      caption: account.maskedNumber,
                    ),
              now: now,
              onLoadMore: cubit.loadMore,
            ),
          };
        },
      ),
    );
  }
}

class _MovementsList extends StatelessWidget {
  const _MovementsList({
    required this.state,
    required this.header,
    required this.now,
    required this.onLoadMore,
  });

  final TransactionsState state;
  final Widget? header;
  final DateTime Function() now;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = now();

    return Column(
      children: [
        if (state.isFromCache) AppOfflineBanner(message: l10n.offlineNotice),
        Expanded(
          // Asks for the next page when the user gets close to the end.
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 400) onLoadMore();
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                if (header != null) ...[
                  header!,
                  const SizedBox(height: AppSpacing.lg),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    l10n.movementsTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.items.isEmpty)
                  AppEmptyView(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.movementsEmptyTitle,
                  ),
                for (final transaction in state.items)
                  TransactionTile(
                    transaction: transaction,
                    dateLabel: formatMovementDate(
                      transaction.createdAt,
                      now: today,
                      l10n: l10n,
                      locale: locale,
                    ),
                  ),
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (state.loadMoreFailed)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Text(l10n.loadMoreError, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: onLoadMore,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
