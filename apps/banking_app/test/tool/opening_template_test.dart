import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/opening_template.dart';

/// Reads a Firestore REST value back as plain JSON, as Firestore does.
Object? _fromFirestore(Map<String, Object?> value) {
  final MapEntry(key: type, value: content) = value.entries.single;
  return switch (type) {
    'integerValue' => int.parse(content! as String),
    'arrayValue' => [
      for (final item in (content! as Map)['values'] as List)
        _fromFirestore(item as Map<String, Object?>),
    ],
    'mapValue' => _fromFields((content! as Map)['fields'] as Map),
    _ => content,
  };
}

Map<String, Object?> _fromFields(Map<dynamic, dynamic> fields) => {
  for (final MapEntry(:key, :value) in fields.entries)
    key as String: _fromFirestore(value as Map<String, Object?>),
};

void main() {
  test('publishes to this repo\'s project unless --project names another', () {
    expect(projectFrom([]), 'bi-digital-banking');
    expect(projectFrom(['--dry-run']), 'bi-digital-banking');
    expect(projectFrom(['--project=my-bank']), 'my-bank');
    expect(projectFrom(['--project=']), 'bi-digital-banking');
  });

  test('every value says its type; integers travel as text', () {
    expect(firestoreValue(45), {'integerValue': '45'});
    expect(firestoreValue('Netflix'), {'stringValue': 'Netflix'});
    expect(firestoreValue(true), {'booleanValue': true});
    expect(firestoreValue(1.5), {'doubleValue': 1.5});
    expect(firestoreValue(null), {'nullValue': null});
    expect(firestoreValue([1]), {
      'arrayValue': {
        'values': [
          {'integerValue': '1'},
        ],
      },
    });
    expect(firestoreValue({'id': 'savings'}), {
      'mapValue': {
        'fields': {
          'id': {'stringValue': 'savings'},
        },
      },
    });
  });

  test('the published template survives the trip to Firestore', () {
    final json =
        jsonDecode(
              File('../../firebase/opening-template.json').readAsStringSync(),
            )
            as Map<String, Object?>;

    final document = firestoreDocument(json);

    expect(_fromFields(document['fields']! as Map), json);
  });
}
