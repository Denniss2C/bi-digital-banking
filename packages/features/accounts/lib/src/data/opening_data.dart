import 'package:accounts/src/domain/entities/account.dart';
import 'package:accounts/src/domain/entities/account_transaction.dart';

/// An opening account with its history, written once when a customer first
/// signs in.
class OpeningAccount {
  const OpeningAccount(this.account, this.transactions);

  final Account account;

  /// Oldest first, with a consistent running balance.
  final List<AccountTransaction> transactions;
}

/// Opening data of a new customer, relative to [now].
///
/// On the Spark plan there is no Cloud Function to provision accounts, so the
/// app writes them on first sign-in (marked `source: seed`). Later movements,
/// such as transfers, are real operations. IDs are deterministic, so writing
/// twice never duplicates data.
List<OpeningAccount> buildOpeningData(DateTime now) => [
  _build(
    now,
    id: 'savings',
    type: AccountType.savings,
    alias: 'Cuenta de Ahorros',
    maskedNumber: '•••• 4892',
    movements: const [
      (45, 150000, 'Depósito de apertura', 'deposit'),
      (42, -6430, 'Supermaxi Mall del Sol', 'groceries'),
      (40, -1099, 'Netflix', 'subscriptions'),
      (38, 185000, 'Abono nómina', 'salary'),
      (36, -4215, 'CNEL Electricidad', 'utilities'),
      (34, -2350, 'Claro Ecuador', 'utilities'),
      (32, -1875, 'Farmacias Fybeca', 'health'),
      (30, -640, 'Uber', 'transport'),
      (28, 35000, 'Transferencia recibida · Carlos Mendoza', 'transfer'),
      (26, -8920, 'Megamaxi', 'groceries'),
      (24, -1250, 'Sweet & Coffee', 'dining'),
      (22, -1499, 'Spotify', 'subscriptions'),
      (20, -4500, 'Gasolinera Primax', 'transport'),
      (18, -3260, 'KFC', 'dining'),
      (16, -9999, 'De Prati', 'shopping'),
      (14, -2100, 'Interagua', 'utilities'),
      (12, -5640, 'Supermaxi', 'groceries'),
      (10, 185000, 'Abono nómina', 'salary'),
      (8, -1590, 'Cinemark', 'entertainment'),
      (6, -780, 'Uber', 'transport'),
      (4, -4320, 'Farmacias Cruz Azul', 'health'),
      (3, -2715, 'Tía', 'groceries'),
      (2, -1099, 'Netflix', 'subscriptions'),
      (1, -690, 'Juan Valdez Café', 'dining'),
    ],
  ),
  _build(
    now,
    id: 'checking',
    type: AccountType.checking,
    alias: 'Cuenta Corriente',
    maskedNumber: '•••• 1203',
    movements: const [
      (30, 50000, 'Depósito de apertura', 'deposit'),
      (25, -12000, 'Pago tarjeta de crédito', 'cards'),
      (15, 25000, 'Transferencia recibida · Andrea Paredes', 'transfer'),
      (7, -4500, 'Pago de servicios · Agua', 'utilities'),
      (2, -3000, 'Retiro en cajero automático', 'cash'),
    ],
  ),
];

/// (days ago, signed amount in cents, description, category)
typedef _Movement = (int, int, String, String);

OpeningAccount _build(
  DateTime now, {
  required String id,
  required AccountType type,
  required String alias,
  required String maskedNumber,
  required List<_Movement> movements,
}) {
  var balance = 0;
  final transactions = <AccountTransaction>[];
  for (final (index, (daysAgo, signedCents, description, category))
      in movements.indexed) {
    balance += signedCents;
    final day = DateTime(now.year, now.month, now.day - daysAgo);
    transactions.add(
      AccountTransaction(
        id: 'opening-$id-${(index + 1).toString().padLeft(2, '0')}',
        type: signedCents >= 0 ? TransactionType.credit : TransactionType.debit,
        amountCents: signedCents.abs(),
        description: description,
        category: category,
        // Distinct times within the day keep a stable order.
        createdAt: day.add(Duration(hours: 9, minutes: index * 7)),
        balanceAfterCents: balance,
      ),
    );
  }
  return OpeningAccount(
    Account(
      id: id,
      type: type,
      alias: alias,
      maskedNumber: maskedNumber,
      balanceCents: balance,
    ),
    transactions,
  );
}
