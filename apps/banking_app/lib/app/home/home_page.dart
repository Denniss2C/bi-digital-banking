import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'dart:developer' as developer;

import 'package:banking_app/app/home/default_home_layout.dart';
import 'package:banking_app/app/home/home_registry.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sdui/sdui.dart';

/// Inicio tab: a greeting and a server-driven layout (SDUI).
///
/// The layout comes from Remote Config for the customer's segment (via
/// [PersonalizationCubit]) and changes live when a new one is published. If
/// it is missing or unusable, the layout embedded in the app is shown.
class HomePage extends StatefulWidget {
  const HomePage({
    required this.accountsRepository,
    required this.userId,
    super.key,
  });

  final AccountsRepository accountsRepository;
  final String userId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SduiRegistry _registry = createHomeRegistry(
    accountsRepository: widget.accountsRepository,
    userId: widget.userId,
  );

  /// Remote layout already resolved, to resolve again only when it changes.
  String? _resolvedSource;
  late SduiResolvedLayout _resolved;

  /// Pull to refresh creates every component again, so each one reloads.
  var _generation = 0;

  SduiResolvedLayout _resolve(String remote) {
    if (remote != _resolvedSource) {
      _resolvedSource = remote;
      _resolved = resolveSduiLayout(
        remote: remote,
        fallback: defaultHomeLayout,
        registry: _registry,
      );
      // Observability (feat/observability) will turn these into events.
      for (final issue in _resolved.issues) {
        developer.log(issue, name: 'sdui.${_resolved.source.name}');
      }
    }
    return _resolved;
  }

  Future<void> _refresh() async {
    await context.read<PersonalizationCubit>().refresh();
    if (mounted) setState(() => _generation++);
  }

  void _onAction(SduiAction action) {
    switch (action) {
      case SduiNavigateAction(:final route):
        // The server may only open screens that exist in this app version...
        if (!AppRoutes.isAppLocation(route)) {
          developer.log('Ignored unknown route "$route"', name: 'sdui');
          return;
        }
        // ...and only features that are enabled right now.
        final flags = context.read<PersonalizationCubit>().state.flags;
        if (!AppRoutes.isEnabled(route, flags)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.featureUnavailable)),
          );
          return;
        }
        context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = _resolve(
      context.select((PersonalizationCubit cubit) => cubit.state.homeLayout),
    );
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Greeting(),
                const SizedBox(height: AppSpacing.lg),
                SduiView(
                  key: ValueKey(_generation),
                  layout: layout.layout,
                  registry: _registry,
                  onAction: _onAction,
                  spacing: AppSpacing.lg,
                  onComponentError: (node, error, _) => developer.log(
                    'Component "${node.type}" failed: $error',
                    name: 'sdui',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "¡Hola, Mateo!" with the section name below, as in the design.
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = context.select<SessionCubit, String?>(
      (session) => switch (session.state) {
        SessionAuthenticated(:final user) => firstName(user.displayName),
        _ => null,
      },
    );
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name == null ? l10n.homeGreetingNoName : l10n.homeGreeting(name),
            style: theme.textTheme.headlineSmall,
          ),
          Text(
            l10n.tabHome,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// First word of a display name, or `null` if there is none.
String? firstName(String? displayName) {
  final words = displayName?.trim().split(RegExp(r'\s+')) ?? const [];
  final first = words.isEmpty ? '' : words.first;
  return first.isEmpty ? null : first;
}
