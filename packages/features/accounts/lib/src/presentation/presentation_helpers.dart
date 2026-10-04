import 'package:accounts/l10n/gen/accounts_localizations.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "Hoy · 11:30", "Ayer · 09:12" or "15 oct" (current locale).
String formatMovementDate(
  DateTime date, {
  required DateTime now,
  required AccountsLocalizations l10n,
  required String locale,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final time = DateFormat.Hm(locale).format(date);
  if (day == today) return '${l10n.today} · $time';
  if (day == today.subtract(const Duration(days: 1))) {
    return '${l10n.yesterday} · $time';
  }
  return DateFormat('d MMM', locale).format(date);
}

/// Icon for a movement category (falls back to a receipt).
IconData categoryIcon(String category) => switch (category) {
  'salary' => Icons.work_outline,
  'deposit' => Icons.savings_outlined,
  'transfer' => Icons.swap_horiz,
  'groceries' => Icons.shopping_cart_outlined,
  'subscriptions' => Icons.subscriptions_outlined,
  'utilities' => Icons.bolt_outlined,
  'health' => Icons.local_pharmacy_outlined,
  'transport' => Icons.directions_car_outlined,
  'dining' => Icons.restaurant_outlined,
  'shopping' => Icons.shopping_bag_outlined,
  'entertainment' => Icons.movie_outlined,
  'cards' => Icons.credit_card,
  'cash' => Icons.atm,
  _ => Icons.receipt_long_outlined,
};

/// Short explanation under an error title.
String failureMessage(AccountsLocalizations l10n, Failure failure) =>
    failure is NetworkFailure
    ? l10n.errorNetworkMessage
    : l10n.errorGenericMessage;
