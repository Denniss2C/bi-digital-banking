import 'package:fx_rates/l10n/gen/fx_localizations.dart';
import 'package:intl/intl.dart';

/// Currencies shown in the converter and the reference list (most relevant
/// for Ecuador first). The provider has more; these have names in the ARB.
const fxCurrencies = [
  'EUR',
  'COP',
  'PEN',
  'MXN',
  'BRL',
  'CLP',
  'ARS',
  'GBP',
  'CAD',
  'JPY',
  'CNY',
];

/// A rate with 4 decimals below 10 (`0.8888`) and 2 above (`3,311.64`).
String formatRate(double rate) =>
    NumberFormat(rate < 10 ? '#,##0.0000' : '#,##0.00', 'en_US').format(rate);

/// An amount in any currency, with its code: `461.25 EUR`.
String formatAmount(double amount, String code) =>
    '${NumberFormat('#,##0.00', 'en_US').format(amount)} $code';

/// Converts [amount] between USD and the currency of [rate] (units of that
/// currency per one USD). Display only: money movements use cents.
double convert({
  required double amount,
  required double rate,
  required bool fromUsd,
}) => fromUsd ? amount * rate : amount / rate;

/// What the user typed (`100`, `100.5` or `100,50`), or `null` if it is not
/// an amount.
double? parseAmount(String text) {
  final value = text.trim();
  if (!RegExp(r'^\d{1,9}([.,]\d{1,2})?$').hasMatch(value)) return null;
  return double.parse(value.replaceAll(',', '.'));
}

/// "Actualizado hace 3 horas", from when the provider published the rates.
String updatedAgo(FxLocalizations l10n, DateTime updatedAt, DateTime now) {
  final elapsed = now.difference(updatedAt);
  if (elapsed.inMinutes < 1) return l10n.updatedJustNow;
  if (elapsed.inMinutes < 60) return l10n.updatedMinutesAgo(elapsed.inMinutes);
  if (elapsed.inHours < 48) return l10n.updatedHoursAgo(elapsed.inHours);
  return l10n.updatedDaysAgo(elapsed.inDays);
}
