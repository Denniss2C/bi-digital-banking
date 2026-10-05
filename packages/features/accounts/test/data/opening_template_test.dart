import 'package:accounts/accounts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/opening_template.dart';

Map<String, Object?> _movement({
  Object daysAgo = 3,
  Object amountCents = 10000,
  Object description = 'Depósito de apertura',
}) => {
  'daysAgo': daysAgo,
  'amountCents': amountCents,
  'description': description,
  'category': 'deposit',
};

Map<String, Object?> _account({
  String id = 'savings',
  String type = 'savings',
  String alias = 'Cuenta de Ahorros',
  List<Object?>? movements,
}) => {
  'id': id,
  'type': type,
  'alias': alias,
  'maskedNumber': '•••• 4892',
  'movements': movements ?? [_movement()],
};

Map<String, Object?> _template(List<Object?> accounts, {Object? version}) => {
  'schemaVersion': ?version,
  'accounts': accounts,
};

Matcher _rejectedWith(String message) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('the published template is valid', () {
    final template = OpeningTemplate.fromJson(openingTemplateJson());

    expect(template.accounts.map((account) => account.id), [
      'savings',
      'checking',
    ]);
  });

  test('reads accounts and movements, oldest first', () {
    final template = OpeningTemplate.fromJson(
      _template([
        _account(
          movements: [
            _movement(daysAgo: 5),
            _movement(daysAgo: 1, amountCents: -2500),
          ],
        ),
      ]),
    );

    final account = template.accounts.single;
    expect(account.type, AccountType.savings);
    expect(account.alias, 'Cuenta de Ahorros');
    expect(account.movements.map((m) => m.amountCents), [10000, -2500]);
  });

  test('accepts whole numbers stored as doubles by the console', () {
    final template = OpeningTemplate.fromJson(
      _template([
        _account(movements: [_movement(daysAgo: 3.0, amountCents: 100.0)]),
      ]),
    );

    expect(template.accounts.single.movements.single.amountCents, 100);
  });

  group('rejects', () {
    final cases = <String, (Map<String, Object?>, String)>{
      'no accounts': (_template([]), '"accounts" must be a non-empty list'),
      'a newer schema': (
        _template([_account()], version: 2),
        'schemaVersion 2 is newer',
      ),
      'an unknown account type': (
        _template([_account(type: 'credit')]),
        'unknown type "credit"',
      ),
      'repeated account ids': (
        _template([_account(), _account()]),
        'ids must be unique',
      ),
      'an id that is not a document id': (
        _template([_account(id: 'Mis Ahorros')]),
        '"id" must be a short lowercase id',
      ),
      'an alias longer than the rules allow': (
        _template([_account(alias: 'x' * 61)]),
        'at most 60 characters',
      ),
      'an account without movements': (
        _template([_account(movements: [])]),
        '"movements" must be a non-empty list',
      ),
      'a balance below zero': (
        _template([
          _account(movements: [_movement(amountCents: -1)]),
        ]),
        'cannot go below zero',
      ),
      'movements out of order': (
        _template([
          _account(movements: [_movement(daysAgo: 1), _movement(daysAgo: 4)]),
        ]),
        'oldest first',
      ),
      'a zero amount': (
        _template([
          _account(movements: [_movement(amountCents: 0)]),
        ]),
        'cannot be zero',
      ),
      'a fractional amount': (
        _template([
          _account(movements: [_movement(amountCents: 10.5)]),
        ]),
        '"amountCents" must be a whole number',
      ),
      'a description longer than the rules allow': (
        _template([
          _account(movements: [_movement(description: 'x' * 141)]),
        ]),
        'at most 140 characters',
      ),
    };
    for (final MapEntry(key: name, value: (json, message)) in cases.entries) {
      test(name, () {
        expect(() => OpeningTemplate.fromJson(json), _rejectedWith(message));
      });
    }
  });
}
