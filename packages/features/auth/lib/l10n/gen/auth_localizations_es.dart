// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AuthLocalizationsEs extends AuthLocalizations {
  AuthLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get onboardingHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get onboardingSignIn => 'Inicia sesión';

  @override
  String onboardingStep(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingBankingTab => 'Banca';

  @override
  String get onboardingBankingTitle => 'Tu banco en tu bolsillo';

  @override
  String get onboardingBankingBody =>
      'Maneja tus cuentas, saldos y transferencias en Ecuador sin pisar una sucursal. 100% digital.';

  @override
  String get onboardingSecurityTab => 'Seguridad';

  @override
  String get onboardingSecurityTitle => 'Seguridad de grado bancario';

  @override
  String get onboardingSecurityBody =>
      'Tu sesión está protegida y tus datos nunca se comparten con terceros.';

  @override
  String get onboardingSavingsTab => 'Ahorro';

  @override
  String get onboardingSavingsTitle => 'Haz crecer tu dinero';

  @override
  String get onboardingSavingsBody =>
      'Revisa tus movimientos y consulta el tipo de cambio en tiempo real.';

  @override
  String get signInTab => 'Iniciar sesión';

  @override
  String get signUpTab => 'Crear cuenta';

  @override
  String get signInHeadline => 'Bienvenido de nuevo';

  @override
  String get signInSubtitle => 'Ingresa a tu banca digital';

  @override
  String get signUpHeadline => 'Abre tu cuenta digital';

  @override
  String get signUpSubtitle => 'En pocos minutos y sin filas';

  @override
  String get nameLabel => 'Nombre completo';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordRules => 'Mínimo 8 caracteres, con letras y números';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get signInAction => 'Iniciar sesión';

  @override
  String get signUpAction => 'Crear cuenta';

  @override
  String get securityTipTitle => 'Consejo de seguridad';

  @override
  String get securityTipBody =>
      'Nunca compartas tu contraseña ni códigos de verificación con nadie, ni siquiera con Nexo.';

  @override
  String get noAccountQuestion => '¿No tienes una cuenta aún?';

  @override
  String get registerAction => 'Registrarme';

  @override
  String get haveAccountQuestion => '¿Ya tienes cuenta?';

  @override
  String get errorNameRequired => 'Ingresa tu nombre';

  @override
  String get errorEmailInvalid => 'Ingresa un correo válido';

  @override
  String get errorPasswordRequired => 'Ingresa tu contraseña';

  @override
  String get errorPasswordWeak =>
      'Usa al menos 8 caracteres, con letras y números';

  @override
  String get errorInvalidCredentials => 'Correo o contraseña incorrectos';

  @override
  String get errorEmailInUse => 'Ya existe una cuenta con este correo';

  @override
  String get errorWeakPassword => 'La contraseña es demasiado débil';

  @override
  String get errorUserDisabled => 'Esta cuenta está deshabilitada';

  @override
  String get errorTooManyRequests =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

  @override
  String get errorNetwork =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get errorUnknown => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String resetEmailSent(String email) {
    return 'Te enviamos un enlace para restablecer tu contraseña a $email.';
  }
}
