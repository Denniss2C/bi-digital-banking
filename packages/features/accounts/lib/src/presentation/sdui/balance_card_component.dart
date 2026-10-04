import 'package:accounts/l10n/gen/accounts_localizations.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:accounts/src/presentation/accounts/accounts_cubit.dart';
import 'package:accounts/src/presentation/presentation_helpers.dart';
import 'package:accounts/src/presentation/widgets/account_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// `balance_card`: live total balance of all the accounts, in the navy hero
/// card of the design. Optional `action` (e.g. open the accounts tab).
class BalanceCardComponent extends StatelessWidget {
  const BalanceCardComponent({
    required this.repository,
    required this.userId,
    this.onTap,
    super.key,
  });

  final AccountsRepository repository;
  final String userId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountsCubit(repository: repository, userId: userId),
      child: BlocBuilder<AccountsCubit, AccountsState>(
        builder: (context, state) {
          final l10n = AccountsLocalizations.of(context);
          return switch (state) {
            AccountsLoading() => _HeroMessage(
              child: AppLoading(semanticsLabel: l10n.accountsLoading),
            ),
            AccountsError(:final failure) => _HeroMessage(
              child: _HeroError(
                title: l10n.accountsErrorTitle,
                message: failureMessage(l10n, failure),
                retryLabel: l10n.retry,
                onRetry: context.read<AccountsCubit>().retry,
              ),
            ),
            AccountsLoaded(:final accounts, :final isFromCache) =>
              BalanceHeroCard(
                label: l10n.totalBalanceLabel,
                totalCents: state.totalCents,
                caption: [
                  if (accounts.isEmpty)
                    l10n.accountsEmptyTitle
                  else
                    l10n.accountsCount(accounts.length),
                  if (isFromCache) l10n.offlineNotice,
                ].join(' · '),
                onTap: onTap,
              ),
          };
        },
      ),
    );
  }
}

/// Navy card of the balance's size, for loading and error states.
class _HeroMessage extends StatelessWidget {
  const _HeroMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.hero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Center(child: child),
      ),
    );
  }
}

class _HeroError extends StatelessWidget {
  const _HeroError({
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
    final textTheme = Theme.of(context).textTheme;
    final onHero = context.semanticColors.onHeroSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(color: onHero),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: onHero),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: retryLabel,
          icon: Icons.refresh,
          expand: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
