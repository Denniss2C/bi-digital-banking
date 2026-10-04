import 'package:accounts/l10n/gen/accounts_localizations.dart';
import 'package:accounts/src/domain/entities/account_transaction.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:accounts/src/presentation/presentation_helpers.dart';
import 'package:accounts/src/presentation/recent_movements/recent_movements_cubit.dart';
import 'package:accounts/src/presentation/widgets/account_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// `tx_list`: the newest movements of all the accounts.
///
/// Props: `title` (default "Movimientos recientes"), `limit` (1 to 10,
/// default 5) and `action` for the "Ver todos" link.
class RecentMovementsComponent extends StatelessWidget {
  const RecentMovementsComponent({
    required this.repository,
    required this.userId,
    required this.limit,
    required this.now,
    this.title,
    this.onSeeAll,
    super.key,
  });

  final AccountsRepository repository;
  final String userId;
  final int limit;
  final DateTime Function() now;
  final String? title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocProvider(
      create: (_) => RecentMovementsCubit(
        repository: repository,
        userId: userId,
        limit: limit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title ?? l10n.recentMovementsTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: Text(l10n.seeAll)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: BlocBuilder<RecentMovementsCubit, RecentMovementsState>(
              builder: (context, state) => switch (state) {
                RecentMovementsLoading() => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppLoading(semanticsLabel: l10n.movementsLoading),
                ),
                RecentMovementsError(:final failure) => _InlineError(
                  title: l10n.movementsErrorTitle,
                  message: failureMessage(l10n, failure),
                  retryLabel: l10n.retry,
                  onRetry: context.read<RecentMovementsCubit>().retry,
                ),
                RecentMovementsLoaded(:final items) when items.isEmpty =>
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      l10n.movementsEmptyTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                RecentMovementsLoaded(:final items, :final isFromCache) =>
                  _MovementList(
                    items: items,
                    isFromCache: isFromCache,
                    now: now,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementList extends StatelessWidget {
  const _MovementList({
    required this.items,
    required this.isFromCache,
    required this.now,
  });

  final List<AccountTransaction> items;
  final bool isFromCache;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFromCache)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              l10n.offlineNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final transaction in items)
          TransactionTile(
            transaction: transaction,
            dateLabel: formatMovementDate(
              transaction.createdAt,
              now: today,
              l10n: l10n,
              locale: locale,
            ),
          ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}
