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
}
