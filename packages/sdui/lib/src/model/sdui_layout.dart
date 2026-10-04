import 'package:equatable/equatable.dart';
import 'package:sdui/src/model/sdui_props.dart';

/// One component of a layout: what to show ([type]) and how ([properties],
/// the `props` object of the JSON).
final class SduiNode extends Equatable {
  const SduiNode({
    required this.type,
    this.id,
    this.properties = const SduiProps.empty(),
  });

  /// Component type, e.g. `promo_banner`.
  final String type;

  /// Optional stable id. It keeps the component's state when the server
  /// reorders the layout, and identifies it in logs and analytics.
  final String? id;

  final SduiProps properties;

  @override
  List<Object?> get props => [type, id, properties];
}

/// A screen described by the server: an ordered list of components.
final class SduiLayout extends Equatable {
  const SduiLayout({
    required this.components,
    this.schemaVersion = 1,
    this.issues = const [],
  });

  /// Highest `schemaVersion` this app understands. A newer document is
  /// rejected, so the app shows its fallback instead of guessing.
  static const supportedSchemaVersion = 1;

  final int schemaVersion;
  final List<SduiNode> components;

  /// Components skipped while parsing, and why (for logs, never for users).
  final List<String> issues;

  @override
  List<Object?> get props => [schemaVersion, components, issues];
}
