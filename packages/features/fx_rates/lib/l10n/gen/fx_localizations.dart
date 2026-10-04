import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'fx_localizations_en.dart';
import 'fx_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FxLocalizations
/// returned by `FxLocalizations.of(context)`.
///
/// Applications need to include `FxLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/fx_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: FxLocalizations.localizationsDelegates,
///   supportedLocales: FxLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the FxLocalizations.supportedLocales
/// property.
abstract class FxLocalizations {
  FxLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FxLocalizations of(BuildContext context) {
    return Localizations.of<FxLocalizations>(context, FxLocalizations)!;
  }

  static const LocalizationsDelegate<FxLocalizations> delegate =
      _FxLocalizationsDelegate();

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

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Divisas'**
  String get fxTitle;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Ecuador (USD). Tasas de referencia del mercado, sin margen de compra o venta.'**
  String get fxSubtitle;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Tasas al día'**
  String get statusLive;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get statusOffline;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Cotizador'**
  String get converterTitle;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get currencyLabel;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Tú tienes'**
  String get youHave;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Recibes aproximadamente'**
  String get youGet;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Invertir la conversión'**
  String get swapDirection;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto válido'**
  String get invalidAmount;

  /// Mid-market rate for one US dollar.
  ///
  /// In es, this message translates to:
  /// **'1 USD = {rate} {code}'**
  String rateLine(String rate, String code);

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Tasa media de mercado: no es una cotización de compra o venta.'**
  String get referenceRateNote;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Tasas de referencia'**
  String get ratesTitle;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Actualizado hace un momento'**
  String get updatedJustNow;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Actualizado hace 1 minuto} other{Actualizado hace {count} minutos}}'**
  String updatedMinutesAgo(int count);

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Actualizado hace 1 hora} other{Actualizado hace {count} horas}}'**
  String updatedHoursAgo(int count);

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Actualizado hace 1 día} other{Actualizado hace {count} días}}'**
  String updatedDaysAgo(int count);

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Actualizando…'**
  String get refreshing;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · mostrando las últimas tasas guardadas'**
  String get offlineNotice;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'No pudimos actualizar · mostrando las últimas tasas guardadas'**
  String get staleNotice;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las tasas'**
  String get errorTitle;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get errorNetworkMessage;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un problema. Inténtalo de nuevo.'**
  String get errorGenericMessage;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// Required by ExchangeRate-API's open access terms. Keep "Rates By Exchange Rate API" verbatim.
  ///
  /// In es, this message translates to:
  /// **'Rates By Exchange Rate API · exchangerate-api.com'**
  String get attribution;

  /// Currency name by ISO code; unknown codes show the code.
  ///
  /// In es, this message translates to:
  /// **'{code, select, USD{Dólar estadounidense} EUR{Euro} COP{Peso colombiano} PEN{Sol peruano} MXN{Peso mexicano} BRL{Real brasileño} CLP{Peso chileno} ARS{Peso argentino} GBP{Libra esterlina} CAD{Dólar canadiense} JPY{Yen japonés} CNY{Yuan chino} other{{code}}}'**
  String currencyName(String code);

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Mercado de divisas'**
  String get widgetTitle;

  /// fx_rates.
  ///
  /// In es, this message translates to:
  /// **'Abrir cotizador'**
  String get widgetOpen;
}

class _FxLocalizationsDelegate extends LocalizationsDelegate<FxLocalizations> {
  const _FxLocalizationsDelegate();

  @override
  Future<FxLocalizations> load(Locale locale) {
    return SynchronousFuture<FxLocalizations>(lookupFxLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_FxLocalizationsDelegate old) => false;
}

FxLocalizations lookupFxLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return FxLocalizationsEn();
    case 'es':
      return FxLocalizationsEs();
  }

  throw FlutterError(
    'FxLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
