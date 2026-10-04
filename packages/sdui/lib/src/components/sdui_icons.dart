import 'package:flutter/material.dart';

/// Icons the server may name in props (`"icon": "transfer"`).
///
/// A closed list keeps the icon set consistent with the design and lets
/// Flutter tree-shake the icon font. An unknown name gets a neutral icon.
const sduiIcons = <String, IconData>{
  'transfer': Icons.swap_horiz,
  'send': Icons.north_east,
  'accounts': Icons.account_balance_wallet_outlined,
  'fx': Icons.currency_exchange,
  'savings': Icons.savings_outlined,
  'trending_up': Icons.trending_up,
  'card': Icons.credit_card,
  'bill': Icons.receipt_long_outlined,
  'qr': Icons.qr_code_2,
  'atm': Icons.local_atm,
  'gift': Icons.card_giftcard,
  'travel': Icons.flight_takeoff,
  'shield': Icons.verified_user_outlined,
  'notifications': Icons.notifications_outlined,
  'profile': Icons.person_outline,
  'info': Icons.info_outline,
  'star': Icons.star_outline,
};

IconData sduiIcon(String? name) => sduiIcons[name] ?? Icons.apps;
