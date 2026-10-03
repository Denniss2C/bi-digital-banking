// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loading => 'Cargando';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabAccounts => 'Cuentas';

  @override
  String get tabFx => 'Divisas';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get comingSoonMessage =>
      'Esta sección llega en las siguientes fases del proyecto.';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginPlaceholderMessage =>
      'El inicio de sesión con Firebase llega en el paso de autenticación. Por ahora puedes continuar a la app.';

  @override
  String get continueAction => 'Continuar';
}
