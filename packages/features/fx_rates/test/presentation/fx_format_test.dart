import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fx_rates/fx_rates.dart';
import 'package:fx_rates/src/presentation/fx_format.dart';

void main() {
  test('rates below 10 keep 4 decimals, larger ones 2', () {
    expect(formatRate(0.888786), '0.8888');
    expect(formatRate(3311.644334), '3,311.64');
  });

  test('amounts carry their currency code', () {
    expect(formatAmount(461.249, 'EUR'), '461.25 EUR');
  });

  test('converts both ways with the rate per dollar', () {
    expect(convert(amount: 100, rate: 0.9, fromUsd: true), closeTo(90, 1e-9));
    expect(convert(amount: 90, rate: 0.9, fromUsd: false), closeTo(100, 1e-9));
  });

  test('accepts amounts with a decimal point or comma', () {
    expect(parseAmount('100'), 100);
    expect(parseAmount(' 100.5 '), 100.5);
    expect(parseAmount('100,25'), 100.25);
    for (final invalid in ['', 'abc', '-5', '1.234', '1,000.00']) {
      expect(parseAmount(invalid), isNull, reason: invalid);
    }
  });

  test('says how long ago the provider published the rates', () {
    final l10n = lookupFxLocalizations(const Locale('es'));
    final at = DateTime.utc(2026, 10, 4);

    expect(updatedAgo(l10n, at, at), 'Actualizado hace un momento');
    expect(
      updatedAgo(l10n, at, at.add(const Duration(minutes: 5))),
      'Actualizado hace 5 minutos',
    );
    expect(
      updatedAgo(l10n, at, at.add(const Duration(hours: 1))),
      'Actualizado hace 1 hora',
    );
    expect(
      updatedAgo(l10n, at, at.add(const Duration(days: 3))),
      'Actualizado hace 3 días',
    );
  });
}
