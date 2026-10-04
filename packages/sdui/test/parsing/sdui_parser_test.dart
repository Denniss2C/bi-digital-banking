import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

import '../helpers.dart';

SduiErrorCode? errorOf(String source) =>
    parseSduiLayout(source).getLeft().toNullable()?.code;

void main() {
  test('reads the components in order, with their id and props', () {
    final layout = layoutOf('''
      {
        "schemaVersion": 1,
        "components": [
          {"type": "balance_card"},
          {"type": "promo_banner", "id": "promo-1", "props": {"title": "Hola"}}
        ]
      }
    ''');

    expect(layout.components, [
      const SduiNode(type: 'balance_card'),
      SduiNode(
        type: 'promo_banner',
        id: 'promo-1',
        properties: SduiProps(const {'title': 'Hola'}),
      ),
    ]);
    expect(layout.issues, isEmpty);
  });

  test('schemaVersion is 1 when missing', () {
    expect(layoutOf('{"components": []}').schemaVersion, 1);
  });

  test('skips malformed components and keeps the rest', () {
    final layout = layoutOf('''
      {"components": [
        "promo_banner",
        {"props": {}},
        {"type": " "},
        {"type": "promo_banner", "props": ["title"]},
        {"type": "quick_actions"}
      ]}
    ''');

    expect(layout.components.map((node) => node.type), ['quick_actions']);
    expect(layout.issues, [
      'components[0]: must be an object',
      'components[1]: missing "type"',
      'components[2]: missing "type"',
      'components[3] (promo_banner): "props" must be an object',
    ]);
  });

  test('rejects documents that are unusable as a whole', () {
    expect(errorOf('not json'), SduiErrorCode.invalidJson);
    expect(errorOf('[]'), SduiErrorCode.invalidShape);
    expect(errorOf('{}'), SduiErrorCode.invalidShape);
    expect(errorOf('{"components": {}}'), SduiErrorCode.invalidShape);
    expect(
      errorOf('{"schemaVersion": "1", "components": []}'),
      SduiErrorCode.invalidShape,
    );
    expect(
      errorOf('{"schemaVersion": 0, "components": []}'),
      SduiErrorCode.invalidShape,
    );
  });

  test('rejects a layout written for a newer app version', () {
    expect(
      errorOf('{"schemaVersion": 2, "components": []}'),
      SduiErrorCode.unsupportedVersion,
    );
  });
}
