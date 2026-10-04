import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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

  /// Screen reader label for generic loading states.
  ///
  /// In es, this message translates to:
  /// **'Cargando'**
  String get loading;

  /// Bottom navigation: home tab.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get tabHome;

  /// Bottom navigation: accounts tab.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get tabAccounts;

  /// Bottom navigation: foreign exchange tab.
  ///
  /// In es, this message translates to:
  /// **'Divisas'**
  String get tabFx;

  /// Bottom navigation: profile tab.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get tabProfile;

  /// Profile: sign out button.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOutAction;

  /// Profile: current account.
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada como {email}'**
  String profileSignedInAs(String email);

  /// Home header with the first name of the customer.
  ///
  /// In es, this message translates to:
  /// **'¡Hola, {name}!'**
  String homeGreeting(String name);

  /// Home header when the customer has no name yet.
  ///
  /// In es, this message translates to:
  /// **'¡Hola!'**
  String get homeGreetingNoName;

  /// Shown when a remotely disabled feature is opened.
  ///
  /// In es, this message translates to:
  /// **'Esta función no está disponible por ahora.'**
  String get featureUnavailable;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Panel de depuración'**
  String get debugEntry;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Solo en dev: modo caos, red y segmentos'**
  String get debugEntryHint;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Red HTTP (modo caos)'**
  String get debugHttpTitle;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Afecta las llamadas HTTP de la app, como Divisas. Los fallos inyectados pasan por los reintentos.'**
  String get debugHttpHint;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Activar modo caos'**
  String get debugChaosEnabled;

  /// Debug panel: injected HTTP latency.
  ///
  /// In es, this message translates to:
  /// **'Latencia: {ms} ms'**
  String debugLatency(int ms);

  /// Debug panel: probability of injected HTTP failures.
  ///
  /// In es, this message translates to:
  /// **'Fallos: {percent}%'**
  String debugFailureRate(int percent);

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Sin red (HTTP)'**
  String get debugHttpOffline;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Sin conexión, la app trabaja con su caché offline: las cuentas muestran el aviso y transferir explica que necesita internet.'**
  String get debugFirestoreHint;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Firestore conectado'**
  String get debugFirestoreOnline;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Segmento del cliente'**
  String get debugSegmentTitle;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Cambia el segmento guardado en Firestore: Remote Config envía en vivo la home de ese segmento.'**
  String get debugSegmentHint;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Remote Config'**
  String get debugRemoteConfigTitle;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Pedir valores ahora'**
  String get debugFetchNow;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get debugOn;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Apagado'**
  String get debugOff;

  /// Action of the in-app banner for a push received while the app is open.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get pushOpen;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Notificaciones push'**
  String get debugPushTitle;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Copia el token y pégalo en la consola de Firebase: Messaging → Enviar mensaje de prueba. Con el dato personalizado route (por ejemplo, /fx), tocar la notificación abre esa pantalla.'**
  String get debugPushHint;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay token: inicia sesión y acepta el permiso.'**
  String get debugPushNoToken;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Copiar token'**
  String get debugCopy;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Token copiado'**
  String get debugCopied;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Observabilidad'**
  String get debugObservabilityTitle;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Los errores llegan a Crashlytics del proyecto dev en unos minutos. El cierre forzado aparece al volver a abrir la app.'**
  String get debugObservabilityHint;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Enviar error de prueba'**
  String get debugSendError;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Error enviado a Crashlytics'**
  String get debugErrorSent;

  /// Debug panel (dev flavor only).
  ///
  /// In es, this message translates to:
  /// **'Forzar cierre de la app (crash)'**
  String get debugCrash;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
