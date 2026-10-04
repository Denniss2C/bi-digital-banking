import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_rates/l10n/gen/fx_localizations.dart';
import 'package:fx_rates/src/domain/fx_rates.dart';
import 'package:fx_rates/src/presentation/fx_cubit.dart';
import 'package:fx_rates/src/presentation/fx_format.dart';
import 'package:sdui/sdui.dart';

/// SDUI components owned by fx_rates, for the shell to register:
/// `registry.registerAll(fxSduiComponents(...))`.
///
/// - `fx_widget`: rates of a few currencies on the home. Props: `currencies`
///   (ISO codes, up to 4; default EUR, COP and PEN) and `action` (e.g. open
///   the converter).
Map<String, SduiComponentBuilder> fxSduiComponents({
  required FxRatesRepository repository,
  DateTime Function() now = DateTime.now,
}) {
  return {
    'fx_widget': (context, props, onAction) {
      final action = props.action('action');
      final currencies = props.strings('currencies');
      return FxWidgetComponent(
        repository: repository,
        currencies: currencies.isEmpty
            ? const ['EUR', 'COP', 'PEN']
            : currencies.take(4).toList(),
        now: now,
        onOpen: action == null ? null : () => onAction(action),
      );
    },
  };
}

/// "Mercado de divisas" card of the home design, with real mid-market rates.
class FxWidgetComponent extends StatelessWidget {
  const FxWidgetComponent({
    required this.repository,
    required this.currencies,
    required this.now,
    this.onOpen,
    super.key,
  });

  final FxRatesRepository repository;
  final List<String> currencies;
  final DateTime Function() now;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = FxLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocProvider(
      create: (_) => FxCubit(repository),
      child: AppCard(
        onTap: onOpen,
        child: BlocBuilder<FxCubit, FxState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.currency_exchange),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.widgetTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (onOpen != null) const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...switch (state) {
                FxLoading() => [AppLoading(semanticsLabel: l10n.refreshing)],
                FxError() => [
                  Text(l10n.errorTitle, style: theme.textTheme.bodyMedium),
                ],
                FxLoaded(:final snapshot) => [
                  for (final code in currencies)
                    if (snapshot.rates.rates[code] case final rate?)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.currencyName(code),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              l10n.rateLine(formatRate(rate), code),
                              style: theme.textTheme.titleSmall?.tabular,
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    snapshot.refreshFailure != null
                        ? l10n.offlineNotice
                        : updatedAgo(l10n, snapshot.rates.updatedAt, now()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}
