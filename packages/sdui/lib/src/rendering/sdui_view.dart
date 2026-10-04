import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:sdui/src/model/sdui_layout.dart';
import 'package:sdui/src/registry/sdui_registry.dart';

/// Reports a component that could not be built (e.g. to Crashlytics).
typedef SduiErrorHandler =
    void Function(SduiNode node, Object error, StackTrace stackTrace);

/// Language for the server's texts: the app's current language.
extension SduiLanguage on BuildContext {
  String get sduiLanguageCode =>
      Localizations.maybeLocaleOf(this)?.languageCode ?? 'es';
}

/// Renders a [SduiLayout] as a vertical list of components.
///
/// - Types that are not registered are skipped (forward compatibility).
/// - A component whose builder throws is skipped and reported to
///   [onComponentError]; the rest of the screen still renders.
/// - Each component is keyed by its `id` (or by its type and position), so
///   it keeps its state when the server reorders the layout.
///
/// It does not scroll: the host screen decides how (e.g. with pull to
/// refresh).
class SduiView extends StatelessWidget {
  const SduiView({
    required this.layout,
    required this.registry,
    required this.onAction,
    this.onComponentError,
    this.spacing = AppSpacing.md,
    super.key,
  });

  final SduiLayout layout;
  final SduiRegistry registry;
  final SduiActionHandler onAction;
  final SduiErrorHandler? onComponentError;

  /// Vertical space between components.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final usedIds = <String>{};
    final positions = <String, int>{};

    for (final node in layout.components) {
      final builder = registry.builderFor(node.type);
      if (builder == null) continue;

      final position = positions.update(
        node.type,
        (count) => count + 1,
        ifAbsent: () => 0,
      );
      // A repeated id from the server must not crash the screen with
      // duplicate keys: the second one falls back to its position.
      final id = node.id;
      final key = id != null && usedIds.add(id)
          ? ValueKey('id:$id')
          : ValueKey('position:${node.type}#$position');

      try {
        children.add(
          KeyedSubtree(
            key: key,
            child: builder(context, node.properties, onAction),
          ),
        );
      } on Object catch (error, stackTrace) {
        onComponentError?.call(node, error, stackTrace);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) SizedBox(height: spacing),
          child,
        ],
      ],
    );
  }
}
