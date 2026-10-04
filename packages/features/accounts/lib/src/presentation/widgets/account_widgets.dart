import 'package:accounts/l10n/gen/accounts_localizations.dart';
import 'package:accounts/src/domain/entities/account.dart';
import 'package:accounts/src/domain/entities/account_transaction.dart';
import 'package:accounts/src/presentation/presentation_helpers.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Navy hero card with the total balance ("Saldo total disponible").
class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({
    required this.label,
    required this.totalCents,
    required this.caption,
    this.onTap,
    super.key,
  });

  final String label;
  final int totalCents;
  final String caption;

  /// Makes the whole card a button (e.g. on the home, to open the accounts).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Theme text styles carry the onSurface (dark) color, which would win
    // over the card's light default; every text sets onHeroSurface.
    final onHero = context.semanticColors.onHeroSurface;
    return AppCard(
      variant: AppCardVariant.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      semanticsLabel: '$label: ${formatUsd(totalCents)}. $caption',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(color: onHero),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Scales down instead of wrapping at large text sizes.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatUsd(totalCents),
              style: textTheme.displayLarge?.copyWith(color: onHero).tabular,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(caption, style: textTheme.bodyMedium?.copyWith(color: onHero)),
        ],
      ),
    );
  }
}

/// One account in the list: alias, number, type and balance.
class AccountCard extends StatelessWidget {
  const AccountCard({required this.account, required this.onTap, super.key});

  final Account account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    final theme = Theme.of(context);
    final isSavings = account.type == AccountType.savings;
    return AppCard(
      onTap: onTap,
      semanticsLabel: l10n.accountCardSemantics(
        account.alias,
        account.maskedNumber,
        formatUsd(account.balanceCents),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            child: Icon(
              isSavings
                  ? Icons.savings_outlined
                  : Icons.account_balance_wallet_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.alias, style: theme.textTheme.titleMedium),
                Text(
                  '${isSavings ? l10n.savingsType : l10n.checkingType} · '
                  '${account.maskedNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.availableBalance,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatUsd(account.balanceCents),
                    style: theme.textTheme.headlineMedium?.tabular,
                  ),
                ),
              ],
            ),
          ),
          const ExcludeSemantics(child: Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

/// One movement: category icon, description, date and signed amount.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.dateLabel,
    super.key,
  });

  final AccountTransaction transaction;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.semanticColors;
    final isCredit = transaction.type == TransactionType.credit;
    final amount = formatUsd(transaction.amountCents);
    final amountText = formatSignedUsd(transaction.signedAmountCents);
    final semantics =
        '${transaction.description}, '
        '${isCredit ? l10n.creditSemantics(amount) : l10n.debitSemantics(amount)}, '
        '$dateLabel';

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.surfaceContainer,
              foregroundColor: theme.colorScheme.onSurface,
              child: Icon(categoryIcon(transaction.category), size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              amountText,
              style: theme.textTheme.titleSmall
                  ?.copyWith(
                    color: isCredit ? colors.positive : colors.negative,
                  )
                  .tabular,
            ),
          ],
        ),
      ),
    );
  }
}
