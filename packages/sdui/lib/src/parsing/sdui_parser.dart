import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui/src/model/sdui_layout.dart';
import 'package:sdui/src/model/sdui_props.dart';

enum SduiErrorCode {
  /// The source is not valid JSON.
  invalidJson,

  /// Valid JSON, but not a layout (e.g. `components` is not a list).
  invalidShape,

  /// Written for a newer app version (`schemaVersion` too high).
  unsupportedVersion,
}

/// Why a whole layout document was rejected.
final class SduiError extends Equatable {
  const SduiError(this.code, this.message);

  final SduiErrorCode code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}

/// Parses a layout document. Never throws.
///
/// Only a document that is unusable as a whole fails: not JSON, the wrong
/// shape, or a newer `schemaVersion`. A malformed component is skipped and
/// noted in [SduiLayout.issues], so one bad entry never hides the rest of
/// the screen.
Either<SduiError, SduiLayout> parseSduiLayout(String source) {
  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException catch (error) {
    return Left(SduiError(SduiErrorCode.invalidJson, error.message));
  }

  if (json is! Map<String, Object?>) {
    return const Left(
      SduiError(SduiErrorCode.invalidShape, 'The layout must be an object'),
    );
  }
  final version = json['schemaVersion'] ?? 1;
  if (version is! int || version < 1) {
    return const Left(
      SduiError(
        SduiErrorCode.invalidShape,
        '"schemaVersion" must be a positive integer',
      ),
    );
  }
  if (version > SduiLayout.supportedSchemaVersion) {
    return Left(
      SduiError(
        SduiErrorCode.unsupportedVersion,
        'schemaVersion $version is newer than '
        '${SduiLayout.supportedSchemaVersion}',
      ),
    );
  }
  final rawComponents = json['components'];
  if (rawComponents is! List<Object?>) {
    return const Left(
      SduiError(SduiErrorCode.invalidShape, '"components" must be a list'),
    );
  }

  final components = <SduiNode>[];
  final issues = <String>[];
  for (final (index, raw) in rawComponents.indexed) {
    if (raw is! Map<String, Object?>) {
      issues.add('components[$index]: must be an object');
      continue;
    }
    final type = raw['type'];
    if (type is! String || type.trim().isEmpty) {
      issues.add('components[$index]: missing "type"');
      continue;
    }
    final props = raw['props'] ?? const <String, Object?>{};
    if (props is! Map<String, Object?>) {
      issues.add('components[$index] ($type): "props" must be an object');
      continue;
    }
    final id = raw['id'];
    components.add(
      SduiNode(
        type: type,
        id: id is String && id.isNotEmpty ? id : null,
        properties: SduiProps(props),
      ),
    );
  }

  return Right(
    SduiLayout(schemaVersion: version, components: components, issues: issues),
  );
}
