import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'auth_localizations_en.dart';
import 'auth_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AuthLocalizations
/// returned by `AuthLocalizations.of(context)`.
///
/// Applications need to include `AuthLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/auth_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AuthLocalizations.localizationsDelegates,
///   supportedLocales: AuthLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AuthLocalizations.supportedLocales
/// property.
abstract class AuthLocalizations {
  AuthLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AuthLocalizations of(BuildContext context) {
    return Localizations.of<AuthLocalizations>(context, AuthLocalizations)!;
  }

  static const LocalizationsDelegate<AuthLocalizations> delegate =
      _AuthLocalizationsDelegate();

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

  /// No description provided for @onboardingSkip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get onboardingSkip;

  /// No description provided for @onboardingContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboardingContinue;

  /// No description provided for @onboardingStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onboardingStart;

  /// No description provided for @onboardingHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get onboardingHaveAccount;

  /// No description provided for @onboardingSignIn.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get onboardingSignIn;

  /// Screen reader progress of the onboarding slides.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @onboardingBankingTab.
  ///
  /// In es, this message translates to:
  /// **'Banca'**
  String get onboardingBankingTab;

  /// No description provided for @onboardingBankingTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu banco en tu bolsillo'**
  String get onboardingBankingTitle;

  /// No description provided for @onboardingBankingBody.
  ///
  /// In es, this message translates to:
  /// **'Maneja tus cuentas, saldos y transferencias en Ecuador sin pisar una sucursal. 100% digital.'**
  String get onboardingBankingBody;

  /// No description provided for @onboardingSecurityTab.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get onboardingSecurityTab;

  /// No description provided for @onboardingSecurityTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguridad de grado bancario'**
  String get onboardingSecurityTitle;

  /// No description provided for @onboardingSecurityBody.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión está protegida y tus datos nunca se comparten con terceros.'**
  String get onboardingSecurityBody;

  /// No description provided for @onboardingSavingsTab.
  ///
  /// In es, this message translates to:
  /// **'Ahorro'**
  String get onboardingSavingsTab;

  /// No description provided for @onboardingSavingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Haz crecer tu dinero'**
  String get onboardingSavingsTitle;

  /// No description provided for @onboardingSavingsBody.
  ///
  /// In es, this message translates to:
  /// **'Revisa tus movimientos y consulta el tipo de cambio en tiempo real.'**
  String get onboardingSavingsBody;

  /// No description provided for @signInTab.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signInTab;

  /// No description provided for @signUpTab.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get signUpTab;

  /// No description provided for @signInHeadline.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo'**
  String get signInHeadline;

  /// No description provided for @signInSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa a tu banca digital'**
  String get signInSubtitle;

  /// No description provided for @signUpHeadline.
  ///
  /// In es, this message translates to:
  /// **'Abre tu cuenta digital'**
  String get signUpHeadline;

  /// No description provided for @signUpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'En pocos minutos y sin filas'**
  String get signUpSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @passwordRules.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres, con letras y números'**
  String get passwordRules;

  /// No description provided for @showPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @signInAction.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get signInAction;

  /// No description provided for @signUpAction.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get signUpAction;

  /// No description provided for @securityTipTitle.
  ///
  /// In es, this message translates to:
  /// **'Consejo de seguridad'**
  String get securityTipTitle;

  /// No description provided for @securityTipBody.
  ///
  /// In es, this message translates to:
  /// **'Nunca compartas tu contraseña ni códigos de verificación con nadie, ni siquiera con Nexo.'**
  String get securityTipBody;

  /// No description provided for @noAccountQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes una cuenta aún?'**
  String get noAccountQuestion;

  /// No description provided for @registerAction.
  ///
  /// In es, this message translates to:
  /// **'Registrarme'**
  String get registerAction;

  /// No description provided for @haveAccountQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get haveAccountQuestion;

  /// No description provided for @errorNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre'**
  String get errorNameRequired;

  /// No description provided for @errorEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get errorEmailInvalid;

  /// No description provided for @errorPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get errorPasswordRequired;

  /// No description provided for @errorPasswordWeak.
  ///
  /// In es, this message translates to:
  /// **'Usa al menos 8 caracteres, con letras y números'**
  String get errorPasswordWeak;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este correo'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es demasiado débil'**
  String get errorWeakPassword;

  /// No description provided for @errorUserDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta está deshabilitada'**
  String get errorUserDisabled;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.'**
  String get errorTooManyRequests;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet e inténtalo de nuevo.'**
  String get errorNetwork;

  /// No description provided for @errorUnknown.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal. Inténtalo de nuevo.'**
  String get errorUnknown;

  /// No description provided for @resetEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace para restablecer tu contraseña a {email}.'**
  String resetEmailSent(String email);
}

class _AuthLocalizationsDelegate
    extends LocalizationsDelegate<AuthLocalizations> {
  const _AuthLocalizationsDelegate();

  @override
  Future<AuthLocalizations> load(Locale locale) {
    return SynchronousFuture<AuthLocalizations>(
      lookupAuthLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AuthLocalizationsDelegate old) => false;
}

AuthLocalizations lookupAuthLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AuthLocalizationsEn();
    case 'es':
      return AuthLocalizationsEs();
  }

  throw FlutterError(
    'AuthLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
