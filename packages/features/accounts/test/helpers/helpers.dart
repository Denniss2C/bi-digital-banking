import 'package:accounts/accounts.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsRepository extends Mock implements AccountsRepository {}

const savings = Account(
  id: 'savings',
  type: AccountType.savings,
  alias: 'Cuenta de Ahorros',
  maskedNumber: '•••• 4892',
  balanceCents: 384550,
);

const checking = Account(
  id: 'checking',
  type: AccountType.checking,
  alias: 'Cuenta Corriente',
  maskedNumber: '•••• 1203',
  balanceCents: 55500,
);

AccountTransaction movement(int index, {DateTime? at}) => AccountTransaction(
  id: 't$index',
  type: index.isEven ? TransactionType.credit : TransactionType.debit,
  amountCents: 1000 + index,
  description: 'Movimiento $index',
  category: 'groceries',
  createdAt: at ?? DateTime(2026, 9, 1).add(Duration(hours: index)),
  balanceAfterCents: 100000,
);

extension PumpAccounts on WidgetTester {
  /// Pumps [child] with the app theme and the accounts strings in Spanish.
  Future<void> pumpLocalized(Widget child) async {
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AccountsLocalizations.localizationsDelegates,
        supportedLocales: AccountsLocalizations.supportedLocales,
        home: child,
      ),
    );
    await pumpAndSettle();
  }
}
