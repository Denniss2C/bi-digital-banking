import 'package:equatable/equatable.dart';
import 'package:sdui/src/model/sdui_layout.dart';
import 'package:sdui/src/parsing/sdui_parser.dart';
import 'package:sdui/src/registry/sdui_registry.dart';

enum SduiLayoutSource { remote, fallback }

/// The layout to show and where it came from.
final class SduiResolvedLayout extends Equatable {
  const SduiResolvedLayout({
    required this.layout,
    required this.source,
    this.issues = const [],
  });

  final SduiLayout layout;
  final SduiLayoutSource source;

  /// What was skipped from the remote layout, or why it was discarded (for
  /// logs and analytics, never for users).
  final List<String> issues;

  @override
  List<Object?> get props => [layout, source, issues];
}

/// Chooses between the [remote] layout and the [fallback] embedded in the
/// app.
///
/// The remote layout wins if it parses and has at least one component this
/// app can render. Otherwise the screen would be broken or empty, so the
/// fallback is used and the reason is reported. The fallback ships with the
/// app and must always parse: if it does not, this throws [StateError] (a
/// bug that tests catch, not a runtime condition).
SduiResolvedLayout resolveSduiLayout({
  required String? remote,
  required String fallback,
  required SduiRegistry registry,
}) {
  final reasons = <String>[];

  if (remote == null || remote.trim().isEmpty) {
    reasons.add('No remote layout');
  } else {
    final parsed = parseSduiLayout(remote);
    final layout = parsed.getRight().toNullable();
    if (layout == null) {
      final error = parsed.getLeft().toNullable()!;
      reasons.add(
        'Remote layout rejected (${error.code.name}): '
        '${error.message}',
      );
    } else {
      final unknownTypes = {
        for (final node in layout.components)
          if (!registry.supports(node.type)) node.type,
      };
      final issues = [
        ...layout.issues,
        for (final type in unknownTypes) 'Unknown component "$type" (skipped)',
      ];
      if (layout.components.any((node) => registry.supports(node.type))) {
        return SduiResolvedLayout(
          layout: layout,
          source: SduiLayoutSource.remote,
          issues: issues,
        );
      }
      reasons
        ..addAll(issues)
        ..add('Remote layout has no component this app can render');
    }
  }

  final fallbackLayout = parseSduiLayout(fallback).getOrElse(
    (error) => throw StateError('Invalid fallback layout: ${error.message}'),
  );
  return SduiResolvedLayout(
    layout: fallbackLayout,
    source: SduiLayoutSource.fallback,
    issues: reasons,
  );
}
