import 'package:accounts/src/data/opening_template.dart';
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

/// Opening data of a new customer from [template], dated relative to [now].
///
/// On the Spark plan there is no Cloud Function to provision accounts, so the
/// app writes them on first sign-in (marked `source: seed`). The data comes
/// from the template in Firestore, not from the app. Later movements, such as
/// transfers, are real operations. IDs are deterministic, so writing twice
/// never duplicates data.
List<OpeningAccount> buildOpeningData(DateTime now, OpeningTemplate template) =>
    [for (final account in template.accounts) _build(now, account)];

OpeningAccount _build(DateTime now, OpeningTemplateAccount template) {
  var balance = 0;
  final transactions = <AccountTransaction>[];
  for (final (index, movement) in template.movements.indexed) {
    balance += movement.amountCents;
    final day = DateTime(now.year, now.month, now.day - movement.daysAgo);
    transactions.add(
      AccountTransaction(
        id: 'opening-${template.id}-${(index + 1).toString().padLeft(2, '0')}',
        type: movement.amountCents >= 0
            ? TransactionType.credit
            : TransactionType.debit,
        amountCents: movement.amountCents.abs(),
        description: movement.description,
        category: movement.category,
        // Distinct times within the day keep a stable order.
        createdAt: day.add(Duration(hours: 9, minutes: index * 7)),
        balanceAfterCents: balance,
      ),
    );
  }
  return OpeningAccount(
    Account(
      id: template.id,
      type: template.type,
      alias: template.alias,
      maskedNumber: template.maskedNumber,
      balanceCents: balance,
    ),
    transactions,
  );
}
