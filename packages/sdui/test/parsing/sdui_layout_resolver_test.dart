import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

import '../helpers.dart';

void main() {
  final registry = SduiRegistry({
    'promo_banner': emptyComponent,
    'quick_actions': emptyComponent,
  });
  const fallback = '{"components": [{"type": "quick_actions"}]}';

  SduiResolvedLayout resolve(String? remote) =>
      resolveSduiLayout(remote: remote, fallback: fallback, registry: registry);

  test('uses the remote layout and reports what it skips', () {
    final resolved = resolve('''
      {"components": [
        {"type": "promo_banner"},
        {"type": "stories"},
        {"props": {}}
      ]}
    ''');

    expect(resolved.source, SduiLayoutSource.remote);
    expect(resolved.layout.components.map((node) => node.type), [
      'promo_banner',
      'stories',
    ]);
    expect(resolved.issues, [
      'components[2]: missing "type"',
      'Unknown component "stories" (skipped)',
    ]);
  });

  for (final (description, remote) in [
    ('missing', null),
    ('blank', '  '),
    ('not JSON', '{oops'),
    (
      'from a newer schema',
      '{"schemaVersion": 9, "components": [{"type": "promo_banner"}]}',
    ),
    ('without renderable components', '{"components": [{"type": "stories"}]}'),
  ]) {
    test('falls back when the remote layout is $description', () {
      final resolved = resolve(remote);

      expect(resolved.source, SduiLayoutSource.fallback);
      expect(resolved.layout.components.single.type, 'quick_actions');
      expect(resolved.issues, isNotEmpty);
    });
  }

  test('an invalid fallback is a bug, not a runtime condition', () {
    expect(
      () => resolveSduiLayout(remote: null, fallback: '[]', registry: registry),
      throwsStateError,
    );
  });
}
