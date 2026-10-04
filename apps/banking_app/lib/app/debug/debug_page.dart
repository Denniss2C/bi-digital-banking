import 'package:accounts/accounts.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Debug panel (dev flavor only): switches to show how the app behaves
/// degraded and recovers, and to change the personalization live.
class DebugPage extends StatefulWidget {
  const DebugPage({
    required this.tools,
    required this.accounts,
    required this.userId,
    super.key,
  });

  final DebugTools tools;
  final AccountsRepository accounts;
  final String userId;

  /// Segments with their own home in the Remote Config template.
  static const segments = ['new_user', 'saver', 'traveler'];

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  // Created once: building them in build() would ask again on every rebuild.
  late final _segment = widget.accounts.watchSegment(widget.userId);
  late final _pushToken = widget.tools.push.token();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chaos = widget.tools.chaos;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.debugEntry)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _Section(
            title: l10n.debugHttpTitle,
            hint: l10n.debugHttpHint,
            child: ValueListenableBuilder<ChaosConfig>(
              valueListenable: chaos,
              builder: (context, config, _) => Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.debugChaosEnabled),
                    value: config.enabled,
                    onChanged: (enabled) =>
                        chaos.value = config.copyWith(enabled: enabled),
                  ),
                  _SliderTile(
                    label: l10n.debugLatency(config.latency.inMilliseconds),
                    value: config.latency.inMilliseconds.toDouble(),
                    max: 5000,
                    onChanged: config.enabled
                        ? (ms) => chaos.value = config.copyWith(
                            latency: Duration(milliseconds: ms.round()),
                          )
                        : null,
                  ),
                  _SliderTile(
                    label: l10n.debugFailureRate(
                      (config.failureRate * 100).round(),
                    ),
                    value: config.failureRate,
                    max: 1,
                    onChanged: config.enabled
                        ? (rate) =>
                              chaos.value = config.copyWith(failureRate: rate)
                        : null,
                  ),
                  SwitchListTile(
                    title: Text(l10n.debugHttpOffline),
                    value: config.offline,
                    onChanged: config.enabled
                        ? (offline) =>
                              chaos.value = config.copyWith(offline: offline)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          _Section(
            title: 'Firestore',
            hint: l10n.debugFirestoreHint,
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.tools.firestoreNetwork,
              builder: (context, online, _) => SwitchListTile(
                title: Text(l10n.debugFirestoreOnline),
                value: online,
                onChanged: (enabled) =>
                    widget.tools.firestoreNetwork.setEnabled(enabled: enabled),
              ),
            ),
          ),
          _Section(
            title: l10n.debugSegmentTitle,
            hint: l10n.debugSegmentHint,
            child: StreamBuilder(
              stream: _segment,
              builder: (context, snapshot) {
                final current = snapshot.data?.getRight().toNullable();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: SegmentedButton<String>(
                    segments: [
                      for (final segment in DebugPage.segments)
                        ButtonSegment(value: segment, label: Text(segment)),
                    ],
                    selected: {?current},
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      widget.accounts.setSegment(
                        userId: widget.userId,
                        segment: selection.single,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _Section(
            title: l10n.debugPushTitle,
            hint: l10n.debugPushHint,
            child: FutureBuilder<String?>(
              future: _pushToken,
              builder: (context, snapshot) {
                final token = snapshot.data;
                if (token == null) {
                  return ListTile(title: Text(l10n.debugPushNoToken));
                }
                return Column(
                  children: [
                    ListTile(
                      title: SelectableText(
                        token,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: AppButton(
                        label: l10n.debugCopy,
                        icon: Icons.copy,
                        variant: AppButtonVariant.tertiary,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: token));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.debugCopied)),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _Section(
            title: l10n.debugRemoteConfigTitle,
            child: BlocBuilder<PersonalizationCubit, PersonalizationConfig>(
              builder: (context, config) => Column(
                children: [
                  for (final (key, enabled) in [
                    (
                      PersonalizationKeys.transfersEnabled,
                      config.flags.transfers,
                    ),
                    (PersonalizationKeys.fxEnabled, config.flags.fx),
                    (
                      PersonalizationKeys.aiAssistantEnabled,
                      config.flags.aiAssistant,
                    ),
                  ])
                    ListTile(
                      dense: true,
                      title: Text(key),
                      trailing: Text(enabled ? l10n.debugOn : l10n.debugOff),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppButton(
                      label: l10n.debugFetchNow,
                      icon: Icons.cloud_download_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          context.read<PersonalizationCubit>().refresh(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.hint});

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Slider(
        value: value,
        max: max,
        divisions: 10,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}
