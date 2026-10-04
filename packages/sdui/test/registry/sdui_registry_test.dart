import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

import '../helpers.dart';

void main() {
  test('knows the registered types', () {
    final registry = SduiRegistry({'a': emptyComponent})
      ..register('b', emptyComponent);

    expect(registry.supports('a'), isTrue);
    expect(registry.supports('c'), isFalse);
    expect(registry.builderFor('c'), isNull);
    expect(registry.types, {'a', 'b'});
  });

  test('two components with the same type is a bug', () {
    final registry = SduiRegistry({'a': emptyComponent});

    expect(() => registry.register('a', emptyComponent), throwsStateError);
  });

  test('the standard components need no feature data', () {
    expect(SduiRegistry(standardSduiComponents).types, {
      'promo_banner',
      'quick_actions',
    });
  });
}
