import 'package:accounts/l10n/gen/accounts_localizations.dart';
import 'package:accounts/src/domain/entities/transfer.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:accounts/src/domain/usecases/transfer_between_own_accounts.dart';
import 'package:accounts/src/presentation/transfer/transfer_cubit.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Transfer between the customer's own accounts ("Transferir" screen of the
/// design, option "A cuentas Nexo").
class TransferPage extends StatelessWidget {
  const TransferPage({
    required this.repository,
    required this.userId,
    required this.onDone,
    super.key,
  });

  final AccountsRepository repository;
  final String userId;

  /// Leaves the flow (the shell decides where to go).
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransferCubit(repository: repository, userId: userId),
      child: _TransferView(onDone: onDone),
    );
  }
}

/// Localized text for a broken transfer rule.
String transferErrorMessage(AccountsLocalizations l10n, TransferError error) {
  return switch (error) {
    TransferError.sameAccount => l10n.errorSameAccount,
    TransferError.invalidAmount => l10n.errorInvalidAmount,
    TransferError.limitExceeded => l10n.errorLimitExceeded(
      formatUsd(TransferBetweenOwnAccounts.maxAmountCents),
    ),
    TransferError.conceptTooLong => l10n.errorConceptTooLong(
      TransferBetweenOwnAccounts.maxConceptLength,
    ),
    TransferError.insufficientFunds => l10n.errorInsufficientFunds,
    TransferError.accountNotFound => l10n.errorAccountNotFound,
  };
}

/// Localized text for a failed transfer request.
String transferFailureMessage(AccountsLocalizations l10n, Failure failure) {
  return switch (failure) {
    ValidationFailure(:final code) =>
      TransferError.values.where((e) => e.name == code).firstOrNull == null
          ? l10n.errorGenericMessage
          : transferErrorMessage(l10n, TransferError.values.byName(code)),
    NetworkFailure() => l10n.errorTransferOffline,
    _ => l10n.errorGenericMessage,
  };
}

class _TransferView extends StatefulWidget {
  const _TransferView({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_TransferView> createState() => _TransferViewState();
}

class _TransferViewState extends State<_TransferView> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferTitle)),
      body: BlocBuilder<TransferCubit, TransferState>(
        builder: (context, state) {
          final cubit = context.read<TransferCubit>();
          if (state.status == TransferStatus.loadingAccounts) {
            return AppLoading(semanticsLabel: l10n.accountsLoading);
          }
          if (state.accounts.isEmpty) {
            return AppErrorView(
              title: l10n.accountsErrorTitle,
              message: l10n.errorGenericMessage,
              retryLabel: l10n.backToAccounts,
              onRetry: widget.onDone,
            );
          }
          if (state.status == TransferStatus.success) {
            return _TransferSuccess(
              state: state,
              onDone: widget.onDone,
              onNewTransfer: () {
                _amount.clear();
                cubit.restart();
              },
            );
          }
          return _TransferForm(state: state, amount: _amount);
        },
      ),
    );
  }
}

class _TransferForm extends StatelessWidget {
  const _TransferForm({required this.state, required this.amount});

  final TransferState state;
  final TextEditingController amount;

  static const _quickAmounts = [2000, 5000, 10000, 15000];

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<TransferCubit>();
    final error = state.showErrors ? state.validationError : null;
    String? errorFor(Set<TransferError> errors) =>
        error != null && errors.contains(error)
        ? transferErrorMessage(l10n, error)
        : null;

    // A plain scroll view, not a lazy ListView: fields scrolled off screen
    // must keep what the user typed.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.transferToOwnAccounts,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: state.fromId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.fromLabel),
            items: [
              for (final account in state.accounts)
                DropdownMenuItem(
                  value: account.id,
                  child: Text(
                    l10n.accountOption(
                      account.alias,
                      formatUsd(account.balanceCents),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: state.isSubmitting
                ? null
                : (id) => cubit.fromChanged(id!),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: state.toId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.toLabel,
              errorText: errorFor({TransferError.sameAccount}),
            ),
            items: [
              for (final account in state.accounts)
                DropdownMenuItem(
                  value: account.id,
                  child: Text(account.alias, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: state.isSubmitting ? null : (id) => cubit.toChanged(id!),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: amount,
            enabled: !state.isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineMedium?.tabular,
            decoration: InputDecoration(
              labelText: l10n.amountLabel,
              prefixText: r'$ ',
              errorMaxLines: 2,
              errorText: errorFor({
                TransferError.invalidAmount,
                TransferError.limitExceeded,
                TransferError.insufficientFunds,
              }),
            ),
            onChanged: cubit.amountChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final cents in _quickAmounts)
                ActionChip(
                  label: Text(formatUsd(cents)),
                  onPressed: state.isSubmitting
                      ? null
                      : () {
                          final text = '${cents ~/ 100}';
                          amount.text = text;
                          cubit.amountChanged(text);
                        },
                ),
            ],
          ),
          if (state.from != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.availableInAccount(formatUsd(state.from!.balanceCents)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            enabled: !state.isSubmitting,
            maxLength: TransferBetweenOwnAccounts.maxConceptLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.conceptLabel,
              errorText: errorFor({TransferError.conceptTooLong}),
            ),
            onChanged: cubit.conceptChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: AppRadius.buttonBorder,
            ),
            child: Text(
              l10n.transferCost,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          if (state.status == TransferStatus.failure && state.failure != null)
            Semantics(
              liveRegion: true,
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: AppRadius.buttonBorder,
                ),
                child: Text(
                  transferFailureMessage(l10n, state.failure!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.transferAction,
            icon: Icons.send_outlined,
            isLoading: state.isSubmitting,
            onPressed: cubit.submit,
          ),
        ],
      ),
    );
  }
}

class _TransferSuccess extends StatelessWidget {
  const _TransferSuccess({
    required this.state,
    required this.onDone,
    required this.onNewTransfer,
  });

  final TransferState state;
  final VoidCallback onDone;
  final VoidCallback onNewTransfer;

  @override
  Widget build(BuildContext context) {
    final l10n = AccountsLocalizations.of(context);
    final theme = Theme.of(context);
    final receipt = state.receipt!;
    final fromAlias = state.from?.alias ?? receipt.fromAccountId;
    final toAlias = state.to?.alias ?? receipt.toAccountId;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: context.semanticColors.positive,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              header: true,
              child: Text(
                l10n.transferSuccessTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.transferSuccessMessage(
                formatUsd(receipt.amountCents),
                fromAlias,
                toAlias,
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.backToAccounts,
              icon: Icons.account_balance_wallet_outlined,
              onPressed: onDone,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.newTransfer,
              variant: AppButtonVariant.tertiary,
              onPressed: onNewTransfer,
            ),
          ],
        ),
      ),
    );
  }
}
