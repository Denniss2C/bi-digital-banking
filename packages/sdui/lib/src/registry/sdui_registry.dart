import 'package:flutter/widgets.dart';
import 'package:sdui/src/model/sdui_action.dart';
import 'package:sdui/src/model/sdui_props.dart';

/// Runs an action requested by a component (the shell provides it).
typedef SduiActionHandler = void Function(SduiAction action);

/// Builds the widget of one component type from its props.
///
/// Read and validate the props here, not inside a widget's `build`: an
/// exception thrown here (e.g. [SduiPropsException]) makes the renderer skip
/// only this component.
typedef SduiComponentBuilder =
    Widget Function(
      BuildContext context,
      SduiProps props,
      SduiActionHandler onAction,
    );

/// Catalog of the component types this app version can render.
///
/// Each feature contributes its own components (e.g. `balance_card` from
/// accounts) and the shell registers them all, so features never depend on
/// each other. Types that are not registered are ignored when rendering.
class SduiRegistry {
  SduiRegistry([Map<String, SduiComponentBuilder> builders = const {}]) {
    registerAll(builders);
  }

  final _builders = <String, SduiComponentBuilder>{};

  /// Registers [builder] for [type]. Two features claiming the same type is
  /// a bug, so this throws instead of silently replacing the first one.
  void register(String type, SduiComponentBuilder builder) {
    if (_builders.containsKey(type)) {
      throw StateError('SDUI component "$type" is already registered');
    }
    _builders[type] = builder;
  }

  void registerAll(Map<String, SduiComponentBuilder> builders) =>
      builders.forEach(register);

  bool supports(String type) => _builders.containsKey(type);

  SduiComponentBuilder? builderFor(String type) => _builders[type];

  /// Registered types, e.g. to check what the server may send.
  Set<String> get types => Set.unmodifiable(_builders.keys);
}
