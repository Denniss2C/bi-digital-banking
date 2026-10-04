import 'package:equatable/equatable.dart';
import 'package:sdui/src/model/sdui_action.dart';

/// A required prop is missing or invalid. The renderer catches it and skips
/// only the component that threw it.
class SduiPropsException implements Exception {
  const SduiPropsException(this.message);

  final String message;

  @override
  String toString() => 'SduiPropsException: $message';
}

/// Typed, defensive access to the `props` object of a component.
///
/// Reads never throw: a missing value, or one of the wrong type, reads as
/// `null` (or as an empty list). Only the `require*` reads throw, with a
/// [SduiPropsException].
final class SduiProps extends Equatable {
  SduiProps(Map<String, Object?> values) : _values = Map.unmodifiable(values);

  const SduiProps.empty() : _values = const {};

  final Map<String, Object?> _values;

  /// A non-blank string, e.g. an icon name or a tone.
  String? string(String key) => switch (_values[key]) {
    final String value when value.trim().isNotEmpty => value,
    _ => null,
  };

  /// Text for the user: a plain string or one per language, such as
  /// `{"es": "Hola", "en": "Hello"}`. Falls back to Spanish (the app's
  /// default language) and then to any available translation.
  String? text(String key, {required String languageCode}) {
    final value = _values[key];
    final candidates = switch (value) {
      final String text => [text],
      final Map<Object?, Object?> translations => [
        translations[languageCode],
        translations['es'],
        ...translations.values,
      ],
      _ => const <Object?>[],
    };
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) return candidate;
    }
    return null;
  }

  /// Like [text], but throws if there is no text.
  String requireText(String key, {required String languageCode}) =>
      text(key, languageCode: languageCode) ??
      (throw SduiPropsException('"$key" is required'));

  int? integer(String key) => switch (_values[key]) {
    final int value => value,
    _ => null,
  };

  bool? boolean(String key) => switch (_values[key]) {
    final bool value => value,
    _ => null,
  };

  /// A nested object, such as a button: `{"label": ..., "action": ...}`.
  SduiProps? object(String key) => switch (_values[key]) {
    final Map<String, Object?> value => SduiProps(value),
    _ => null,
  };

  /// The objects of a list; any other item in the list is skipped.
  List<SduiProps> objects(String key) => switch (_values[key]) {
    final List<Object?> items => [
      for (final item in items)
        if (item is Map<String, Object?>) SduiProps(item),
    ],
    _ => const [],
  };

  /// The non-blank strings of a list, e.g. currency codes.
  List<String> strings(String key) => switch (_values[key]) {
    final List<Object?> items => [
      for (final item in items)
        if (item is String && item.trim().isNotEmpty) item,
    ],
    _ => const [],
  };

  /// A supported action, or `null` (see [SduiAction.fromJson]).
  SduiAction? action(String key) => SduiAction.fromJson(_values[key]);

  @override
  List<Object?> get props => [_values];
}
