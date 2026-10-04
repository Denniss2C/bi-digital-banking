import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_rates/l10n/gen/fx_localizations.dart';
import 'package:fx_rates/src/domain/fx_rates.dart';
import 'package:fx_rates/src/presentation/fx_cubit.dart';
import 'package:fx_rates/src/presentation/fx_format.dart';

/// Divisas tab: a live converter and reference rates from a public provider,
/// with the last saved rates when it cannot be reached.
class FxPage extends StatelessWidget {
  const FxPage({required this.repository, this.now = DateTime.now, super.key});

  final FxRatesRepository repository;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FxCubit(repository),
      child: _FxView(now: now),
    );
  }
}

class _FxView extends StatelessWidget {
  const _FxView({required this.now});

  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final l10n = FxLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fxTitle)),
      body: BlocBuilder<FxCubit, FxState>(
        builder: (context, state) {
          final cubit = context.read<FxCubit>();
          return switch (state) {
            FxLoading() => AppLoading(semanticsLabel: l10n.refreshing),
            FxError(:final failure) => AppErrorView(
              title: l10n.errorTitle,
              message: failure is NetworkFailure
                  ? l10n.errorNetworkMessage
                  : l10n.errorGenericMessage,
              retryLabel: l10n.retry,
              onRetry: cubit.retry,
            ),
            FxLoaded(:final snapshot) => Column(
              children: [
                if (snapshot.refreshFailure != null)
                  AppOfflineBanner(
                    message: snapshot.refreshFailure is NetworkFailure
                        ? l10n.offlineNotice
                        : l10n.staleNotice,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: cubit.refresh,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.screenMargin),
                      children: [
                        _Header(snapshot: snapshot),
                        const SizedBox(height: AppSpacing.lg),
                        _Converter(rates: snapshot.rates),
                        const SizedBox(height: AppSpacing.lg),
                        _ReferenceRates(rates: snapshot.rates),
                        const SizedBox(height: AppSpacing.md),
                        _Footer(snapshot: snapshot, now: now),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          };
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.snapshot});

  final FxSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = FxLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.semanticColors;
    final offline = snapshot.refreshFailure != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fxSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              offline ? Icons.cloud_off_outlined : Icons.circle,
              size: 12,
              color: offline ? colors.warning : colors.positive,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              offline ? l10n.statusOffline : l10n.statusLive,
              style: theme.textTheme.labelMedium?.copyWith(
                color: offline ? colors.warning : colors.positive,
              ),
            ),
            if (snapshot.isRefreshing) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.refreshing, style: theme.textTheme.labelMedium),
            ],
          ],
        ),
      ],
    );
  }
}

/// Amount in one currency and its equivalent in the other, both ways.
class _Converter extends StatefulWidget {
  const _Converter({required this.rates});

  final FxRates rates;

  @override
  State<_Converter> createState() => _ConverterState();
}

class _ConverterState extends State<_Converter> {
  final _amount = TextEditingController(text: '100');
  var _code = fxCurrencies.first;
  var _fromUsd = true;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FxLocalizations.of(context);
    final theme = Theme.of(context);
    final available = [
      for (final code in fxCurrencies)
        if (widget.rates.rates.containsKey(code)) code,
    ];
    final code = available.contains(_code) ? _code : available.first;
    final rate = widget.rates.rates[code]!;
    final amount = parseAmount(_amount.text);
    final (fromCode, toCode) = _fromUsd ? ('USD', code) : (code, 'USD');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.converterTitle, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: code,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.currencyLabel),
            items: [
              for (final option in available)
                DropdownMenuItem(
                  value: option,
                  child: Text(
                    '$option · ${l10n.currencyName(option)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _code = value!),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineSmall?.tabular,
            decoration: InputDecoration(
              labelText: l10n.youHave,
              suffixText: fromCode,
              errorText: amount == null ? l10n.invalidAmount : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          Center(
            child: IconButton.filled(
              tooltip: l10n.swapDirection,
              icon: const Icon(Icons.swap_vert),
              onPressed: () => setState(() => _fromUsd = !_fromUsd),
            ),
          ),
          Text(
            l10n.youGet,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            liveRegion: true,
            child: Text(
              amount == null
                  ? '—'
                  : formatAmount(
                      convert(amount: amount, rate: rate, fromUsd: _fromUsd),
                      toCode,
                    ),
              style: theme.textTheme.headlineMedium?.tabular,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.rateLine(formatRate(rate), code),
            style: theme.textTheme.bodyMedium?.tabular,
          ),
        ],
      ),
    );
  }
}

class _ReferenceRates extends StatelessWidget {
  const _ReferenceRates({required this.rates});

  final FxRates rates;

  @override
  Widget build(BuildContext context) {
    final l10n = FxLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.ratesTitle, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (final code in fxCurrencies)
                if (rates.rates[code] case final rate?)
                  ListTile(
                    title: Text(l10n.currencyName(code)),
                    subtitle: Text(code),
                    trailing: Text(
                      l10n.rateLine(formatRate(rate), code),
                      style: theme.textTheme.titleSmall?.tabular,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.snapshot, required this.now});

  final FxSnapshot snapshot;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final l10n = FxLocalizations.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(updatedAgo(l10n, snapshot.rates.updatedAt, now()), style: style),
        Text(l10n.referenceRateNote, style: style),
        // Required by the provider's open access terms.
        Text(l10n.attribution, style: style),
      ],
    );
  }
}
