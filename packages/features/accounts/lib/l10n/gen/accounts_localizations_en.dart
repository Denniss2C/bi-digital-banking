// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'accounts_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AccountsLocalizationsEn extends AccountsLocalizations {
  AccountsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get totalBalanceLabel => 'Total available balance';

  @override
  String accountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
    );
    return '$_temp0';
  }

  @override
  String get savingsType => 'Savings';

  @override
  String get checkingType => 'Checking';

  @override
  String get availableBalance => 'Available balance';

  @override
  String accountCardSemantics(String alias, String number, String amount) {
    return '$alias, $number, available balance $amount';
  }

  @override
  String get accountsLoading => 'Loading your accounts';

  @override
  String get accountsEmptyTitle => 'We are preparing your accounts';

  @override
  String get accountsEmptyMessage =>
      'Your accounts will show up here in a few seconds.';

  @override
  String get accountsErrorTitle => 'We couldn\'t load your accounts';

  @override
  String get movementsTitle => 'Movements';

  @override
  String get movementsLoading => 'Loading movements';

  @override
  String get movementsEmptyTitle => 'No movements yet';

  @override
  String get movementsErrorTitle => 'We couldn\'t load your movements';

  @override
  String get loadMoreError => 'We couldn\'t load more movements.';

  @override
  String get errorNetworkMessage => 'Check your connection and try again.';

  @override
  String get errorGenericMessage => 'Something went wrong. Try again.';

  @override
  String get retry => 'Retry';

  @override
  String get offlineNotice => 'Offline · showing your last saved data';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String creditSemantics(String amount) {
    return 'income of $amount';
  }

  @override
  String debitSemantics(String amount) {
    return 'expense of $amount';
  }

  @override
  String get transferAction => 'Transfer';

  @override
  String get transferTitle => 'Transfer money';

  @override
  String get transferToOwnAccounts => 'To Nexo accounts · free and instant';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String accountOption(String alias, String amount) {
    return '$alias · $amount';
  }

  @override
  String get amountLabel => 'Amount to send (USD)';

  @override
  String availableInAccount(String amount) {
    return 'Available in your account: $amount';
  }

  @override
  String get conceptLabel => 'Concept (optional)';

  @override
  String get transferCost => 'Transfer cost: \$0.00 · instant credit';

  @override
  String get errorSameAccount => 'Choose an account different from the source';

  @override
  String get errorInvalidAmount => 'Enter a valid amount';

  @override
  String errorLimitExceeded(String amount) {
    return 'The maximum per transfer is $amount';
  }

  @override
  String errorConceptTooLong(int max) {
    return 'Use at most $max characters';
  }

  @override
  String get errorInsufficientFunds =>
      'Insufficient balance in the source account';

  @override
  String get errorAccountNotFound => 'The account is no longer available';

  @override
  String get errorTransferOffline =>
      'No connection. Transfers need internet; try again.';

  @override
  String get transferSuccessTitle => 'Transfer completed';

  @override
  String transferSuccessMessage(String amount, String from, String to) {
    return '$amount from $from to $to';
  }

  @override
  String get newTransfer => 'New transfer';

  @override
  String get backToAccounts => 'See my accounts';

  @override
  String get seeAll => 'See all';

  @override
  String get recentMovementsTitle => 'Recent activity';
}
