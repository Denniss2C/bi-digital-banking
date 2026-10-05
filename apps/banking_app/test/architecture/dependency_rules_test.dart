// The modularity rules of docs/architecture/dependencies.md, checked on
// every pubspec: breaking one fails CI instead of waiting for a review.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Internal packages each package may depend on. Features never depend on
/// each other: the shell (apps/banking_app) composes them.
const _allowed = {
  'core': <String>{},
  'design_system': <String>{},
  'sdui': {'core', 'design_system'},
  'auth': {'core', 'design_system', 'sdui'},
  'accounts': {'core', 'design_system', 'sdui'},
  'notifications': {'core', 'design_system', 'sdui'},
  'fx_rates': {'core', 'design_system', 'sdui'},
};

void main() {
  // The workspace members (root pubspec.yaml), except the shell, which may
  // depend on everything. Scanning folders would also find the plugin copies
  // that builds leave in packages/*/build.
  final root =
      loadYaml(File('../../pubspec.yaml').readAsStringSync()) as YamlMap;
  final pubspecs = {
    for (final path in (root['workspace'] as YamlList).cast<String>())
      if (path != 'apps/banking_app')
        if (loadYaml(File('../../$path/pubspec.yaml').readAsStringSync())
            case final YamlMap pubspec)
          pubspec['name'] as String: pubspec,
  };

  test('every package has a rule', () {
    expect(pubspecs.keys.toSet(), _allowed.keys.toSet());
  });

  for (final MapEntry(key: name, value: allowed) in _allowed.entries) {
    test(
      '$name depends only on ${allowed.isEmpty ? 'external packages' : allowed.join(', ')}',
      () {
        final pubspec = pubspecs[name]!;
        // Tests count too: a feature test must not import another feature.
        final declared = {
          for (final section in ['dependencies', 'dev_dependencies'])
            ...?(pubspec[section] as YamlMap?)?.keys.cast<String>(),
        };
        final internal = declared.where(_allowed.containsKey).toSet();

        expect(
          internal.difference(allowed),
          isEmpty,
          reason: '$name may only use $allowed among the internal packages',
        );
      },
    );
  }
}
