import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'accounts_localizations_en.dart';
import 'accounts_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AccountsLocalizations
/// returned by `AccountsLocalizations.of(context)`.
///
/// Applications need to include `AccountsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/accounts_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AccountsLocalizations.localizationsDelegates,
///   supportedLocales: AccountsLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AccountsLocalizations.supportedLocales
/// property.
abstract class AccountsLocalizations {
  AccountsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AccountsLocalizations of(BuildContext context) {
    return Localizations.of<AccountsLocalizations>(
      context,
      AccountsLocalizations,
    )!;
  }

  static const LocalizationsDelegate<AccountsLocalizations> delegate =
      _AccountsLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @accountsTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get accountsTitle;

  /// No description provided for @totalBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo total disponible'**
  String get totalBalanceLabel;

  /// No description provided for @accountsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cuenta} other{{count} cuentas}}'**
  String accountsCount(int count);

  /// No description provided for @savingsType.
  ///
  /// In es, this message translates to:
  /// **'Ahorros'**
  String get savingsType;

  /// No description provided for @checkingType.
  ///
  /// In es, this message translates to:
  /// **'Corriente'**
  String get checkingType;

  /// No description provided for @availableBalance.
  ///
  /// In es, this message translates to:
  /// **'Saldo disponible'**
  String get availableBalance;

  /// Screen reader summary of an account card.
  ///
  /// In es, this message translates to:
  /// **'{alias}, {number}, saldo disponible {amount}'**
  String accountCardSemantics(String alias, String number, String amount);

  /// No description provided for @accountsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus cuentas'**
  String get accountsLoading;

  /// No description provided for @accountsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando tus cuentas'**
  String get accountsEmptyTitle;

  /// No description provided for @accountsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'En unos segundos verás tus cuentas aquí.'**
  String get accountsEmptyMessage;

  /// No description provided for @accountsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus cuentas'**
  String get accountsErrorTitle;

  /// No description provided for @movementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get movementsTitle;

  /// No description provided for @movementsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando movimientos'**
  String get movementsLoading;

  /// No description provided for @movementsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes movimientos'**
  String get movementsEmptyTitle;

  /// No description provided for @movementsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus movimientos'**
  String get movementsErrorTitle;

  /// No description provided for @loadMoreError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar más movimientos.'**
  String get loadMoreError;

  /// No description provided for @errorNetworkMessage.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get errorNetworkMessage;

  /// No description provided for @errorGenericMessage.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un problema. Inténtalo de nuevo.'**
  String get errorGenericMessage;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @offlineNotice.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · mostrando tus últimos datos guardados'**
  String get offlineNotice;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @creditSemantics.
  ///
  /// In es, this message translates to:
  /// **'ingreso de {amount}'**
  String creditSemantics(String amount);

  /// No description provided for @debitSemantics.
  ///
  /// In es, this message translates to:
  /// **'gasto de {amount}'**
  String debitSemantics(String amount);

  /// No description provided for @transferAction.
  ///
  /// In es, this message translates to:
  /// **'Transferir'**
  String get transferAction;

  /// No description provided for @transferTitle.
  ///
  /// In es, this message translates to:
  /// **'Transferir dinero'**
  String get transferTitle;

  /// No description provided for @transferToOwnAccounts.
  ///
  /// In es, this message translates to:
  /// **'A cuentas Nexo · gratis e inmediato'**
  String get transferToOwnAccounts;

  /// No description provided for @fromLabel.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In es, this message translates to:
  /// **'Para'**
  String get toLabel;

  /// No description provided for @accountOption.
  ///
  /// In es, this message translates to:
  /// **'{alias} · {amount}'**
  String accountOption(String alias, String amount);

  /// No description provided for @amountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto a enviar (USD)'**
  String get amountLabel;

  /// No description provided for @availableInAccount.
  ///
  /// In es, this message translates to:
  /// **'Disponible en tu cuenta: {amount}'**
  String availableInAccount(String amount);

  /// No description provided for @conceptLabel.
  ///
  /// In es, this message translates to:
  /// **'Concepto o detalle (opcional)'**
  String get conceptLabel;

  /// No description provided for @transferCost.
  ///
  /// In es, this message translates to:
  /// **'Costo de la transferencia: \$0.00 · acreditación inmediata'**
  String get transferCost;

  /// No description provided for @errorSameAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta distinta a la de origen'**
  String get errorSameAccount;

  /// No description provided for @errorInvalidAmount.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto válido'**
  String get errorInvalidAmount;

  /// No description provided for @errorLimitExceeded.
  ///
  /// In es, this message translates to:
  /// **'El máximo por transferencia es {amount}'**
  String errorLimitExceeded(String amount);

  /// No description provided for @errorConceptTooLong.
  ///
  /// In es, this message translates to:
  /// **'Usa máximo {max} caracteres'**
  String errorConceptTooLong(int max);

  /// No description provided for @errorInsufficientFunds.
  ///
  /// In es, this message translates to:
  /// **'Saldo insuficiente en la cuenta de origen'**
  String get errorInsufficientFunds;

  /// No description provided for @errorAccountNotFound.
  ///
  /// In es, this message translates to:
  /// **'La cuenta ya no está disponible'**
  String get errorAccountNotFound;

  /// No description provided for @errorTransferOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Las transferencias necesitan internet; inténtalo de nuevo.'**
  String get errorTransferOffline;

  /// No description provided for @transferSuccessTitle.
  ///
  /// In es, this message translates to:
  /// **'Transferencia exitosa'**
  String get transferSuccessTitle;

  /// No description provided for @transferSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'{amount} de {from} a {to}'**
  String transferSuccessMessage(String amount, String from, String to);

  /// No description provided for @newTransfer.
  ///
  /// In es, this message translates to:
  /// **'Nueva transferencia'**
  String get newTransfer;

  /// No description provided for @backToAccounts.
  ///
  /// In es, this message translates to:
  /// **'Ver mis cuentas'**
  String get backToAccounts;
}

class _AccountsLocalizationsDelegate
    extends LocalizationsDelegate<AccountsLocalizations> {
  const _AccountsLocalizationsDelegate();

  @override
  Future<AccountsLocalizations> load(Locale locale) {
    return SynchronousFuture<AccountsLocalizations>(
      lookupAccountsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AccountsLocalizationsDelegate old) => false;
}

AccountsLocalizations lookupAccountsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AccountsLocalizationsEn();
    case 'es':
      return AccountsLocalizationsEs();
  }

  throw FlutterError(
    'AccountsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
