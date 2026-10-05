import 'package:accounts/accounts.dart';
import 'package:accounts/src/data/opening_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/opening_template.dart';

void main() {
  final now = DateTime(2026, 10, 3, 18);
  // The published template (firebase/opening-template.json).
  final template = OpeningTemplate.fromJson(openingTemplateJson());
  final opening = buildOpeningData(now, template);

  test('opens a savings and a checking account', () {
    expect(opening.map((o) => o.account.type), [
      AccountType.savings,
      AccountType.checking,
    ]);
  });

  test('running balances are consistent and end at the account balance', () {
    for (final OpeningAccount(:account, :transactions) in opening) {
      var balance = 0;
      for (final movement in transactions) {
        balance += movement.signedAmountCents;
        expect(movement.balanceAfterCents, balance, reason: movement.id);
        expect(balance, greaterThanOrEqualTo(0), reason: movement.id);
      }
      expect(account.balanceCents, balance);
    }
  });

  test('movements are in the past, oldest first, with unique stable ids', () {
    final all = opening.expand((o) => o.transactions).toList();

    expect(all.every((t) => t.createdAt.isBefore(now)), isTrue);
    for (final o in opening) {
      final dates = o.transactions.map((t) => t.createdAt).toList();
      expect(dates, [...dates]..sort());
    }
    expect(all.map((t) => t.id).toSet(), hasLength(all.length));
    expect(
      buildOpeningData(now, template).first.transactions.first.id,
      all.first.id,
    );
  });

  test('savings has more than one page of movements (pagination demo)', () {
    expect(opening.first.transactions.length, greaterThan(20));
  });
}
