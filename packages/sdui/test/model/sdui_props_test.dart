import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

void main() {
  final props = SduiProps(const {
    'title': 'Hola',
    'blank': '  ',
    'count': 3,
    'decimal': 2.5,
    'flag': true,
    // English first: the Spanish fallback must not depend on key order.
    'greeting': {'en': 'Hello', 'es': 'Hola'},
    'onlyEnglish': {'en': 'Hello'},
    'button': {
      'label': 'Ver',
      'action': {'type': 'navigate', 'route': '/fx'},
    },
    'items': [
      {'label': 'A'},
      'B',
      null,
      {'label': 'C'},
    ],
    'codes': ['EUR', 3, ' ', 'COP'],
  });

  test('reads are typed: missing or mistyped values are null', () {
    expect(props.string('title'), 'Hola');
    expect(props.string('blank'), isNull);
    expect(props.string('count'), isNull);
    expect(props.string('missing'), isNull);
    expect(props.integer('count'), 3);
    expect(props.integer('decimal'), isNull);
    expect(props.boolean('flag'), isTrue);
    expect(props.boolean('title'), isNull);
  });

  test('texts can be translated, falling back to Spanish', () {
    expect(props.text('greeting', languageCode: 'en'), 'Hello');
    expect(props.text('greeting', languageCode: 'es'), 'Hola');
    expect(props.text('greeting', languageCode: 'fr'), 'Hola');
    expect(props.text('onlyEnglish', languageCode: 'es'), 'Hello');
    expect(props.text('title', languageCode: 'en'), 'Hola');
    expect(props.text('count', languageCode: 'es'), isNull);
  });

  test('requireText throws when there is no text', () {
    expect(
      () => props.requireText('blank', languageCode: 'es'),
      throwsA(isA<SduiPropsException>()),
    );
  });

  test('nested objects and lists keep only valid items', () {
    expect(props.object('button')?.text('label', languageCode: 'es'), 'Ver');
    expect(props.object('title'), isNull);
    expect(props.objects('items').map((item) => item.string('label')), [
      'A',
      'C',
    ]);
    expect(props.objects('title'), isEmpty);
    expect(props.strings('codes'), ['EUR', 'COP']);
  });

  group('actions', () {
    test('navigate opens an in-app route', () {
      expect(
        props.object('button')?.action('action'),
        const SduiNavigateAction('/fx'),
      );
    });

    test('unknown or unsafe actions are not supported', () {
      for (final json in [
        {'type': 'open_url', 'url': 'https://nexo.ec'},
        {'type': 'navigate', 'route': 'https://nexo.ec'},
        {'type': 'navigate', 'route': '//evil.example'},
        {'type': 'navigate'},
        'navigate',
        null,
      ]) {
        expect(SduiAction.fromJson(json), isNull, reason: '$json');
      }
    });
  });
}
