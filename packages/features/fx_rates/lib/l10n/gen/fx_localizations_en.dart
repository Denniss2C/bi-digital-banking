// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fx_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FxLocalizationsEn extends FxLocalizations {
  FxLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get fxTitle => 'Exchange';

  @override
  String get fxSubtitle =>
      'Ecuador (USD). Market reference rates, with no buy or sell margin.';

  @override
  String get statusLive => 'Rates up to date';

  @override
  String get statusOffline => 'Offline';

  @override
  String get converterTitle => 'Converter';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get youHave => 'You have';

  @override
  String get youGet => 'You get about';

  @override
  String get swapDirection => 'Swap the conversion';

  @override
  String get invalidAmount => 'Enter a valid amount';

  @override
  String rateLine(String rate, String code) {
    return '1 USD = $rate $code';
  }

  @override
  String get referenceRateNote => 'Mid-market rate: not a buy or sell quote.';

  @override
  String get ratesTitle => 'Reference rates';

  @override
  String get updatedJustNow => 'Updated just now';

  @override
  String updatedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count minutes ago',
      one: 'Updated 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String updatedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count hours ago',
      one: 'Updated 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String updatedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count days ago',
      one: 'Updated 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get refreshing => 'Updating…';

  @override
  String get offlineNotice => 'Offline · showing the last saved rates';

  @override
  String get staleNotice => 'Could not update · showing the last saved rates';

  @override
  String get errorTitle => 'We couldn\'t load the rates';

  @override
  String get errorNetworkMessage => 'Check your connection and try again.';

  @override
  String get errorGenericMessage => 'Something went wrong. Try again.';

  @override
  String get retry => 'Retry';

  @override
  String get attribution => 'Rates By Exchange Rate API · exchangerate-api.com';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'USD': 'US dollar',
      'EUR': 'Euro',
      'COP': 'Colombian peso',
      'PEN': 'Peruvian sol',
      'MXN': 'Mexican peso',
      'BRL': 'Brazilian real',
      'CLP': 'Chilean peso',
      'ARS': 'Argentine peso',
      'GBP': 'Pound sterling',
      'CAD': 'Canadian dollar',
      'JPY': 'Japanese yen',
      'CNY': 'Chinese yuan',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get widgetTitle => 'Currency market';

  @override
  String get widgetOpen => 'Open converter';
}
