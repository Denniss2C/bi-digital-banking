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
  String get signOutAction => 'Cerrar sesión';

  @override
  String profileSignedInAs(String email) {
    return 'Sesión iniciada como $email';
  }

  @override
  String homeGreeting(String name) {
    return '¡Hola, $name!';
  }

  @override
  String get homeGreetingNoName => '¡Hola!';

  @override
  String get featureUnavailable => 'Esta función no está disponible por ahora.';

  @override
  String get debugEntry => 'Panel de depuración';

  @override
  String get debugEntryHint => 'Solo en dev: modo caos, red y segmentos';

  @override
  String get debugHttpTitle => 'Red HTTP (modo caos)';

  @override
  String get debugHttpHint =>
      'Afecta las llamadas HTTP de la app, como Divisas. Los fallos inyectados pasan por los reintentos.';

  @override
  String get debugChaosEnabled => 'Activar modo caos';

  @override
  String debugLatency(int ms) {
    return 'Latencia: $ms ms';
  }

  @override
  String debugFailureRate(int percent) {
    return 'Fallos: $percent%';
  }

  @override
  String get debugHttpOffline => 'Sin red (HTTP)';

  @override
  String get debugFirestoreHint =>
      'Sin conexión, la app trabaja con su caché offline: las cuentas muestran el aviso y transferir explica que necesita internet.';

  @override
  String get debugFirestoreOnline => 'Firestore conectado';

  @override
  String get debugSegmentTitle => 'Segmento del cliente';

  @override
  String get debugSegmentHint =>
      'Cambia el segmento guardado en Firestore: Remote Config envía en vivo la home de ese segmento.';

  @override
  String get debugRemoteConfigTitle => 'Remote Config';

  @override
  String get debugFetchNow => 'Pedir valores ahora';

  @override
  String get debugOn => 'Activo';

  @override
  String get debugOff => 'Apagado';

  @override
  String get pushOpen => 'Ver';

  @override
  String get debugPushTitle => 'Notificaciones push';

  @override
  String get debugPushHint =>
      'Copia el token y pégalo en la consola de Firebase: Messaging → Enviar mensaje de prueba. Con el dato personalizado route (por ejemplo, /fx), tocar la notificación abre esa pantalla.';

  @override
  String get debugPushNoToken =>
      'Todavía no hay token: inicia sesión y acepta el permiso.';

  @override
  String get debugCopy => 'Copiar token';

  @override
  String get debugCopied => 'Token copiado';

  @override
  String get debugObservabilityTitle => 'Observabilidad';

  @override
  String get debugObservabilityHint =>
      'Los errores llegan a Crashlytics del proyecto dev en unos minutos. El cierre forzado aparece al volver a abrir la app.';

  @override
  String get debugSendError => 'Enviar error de prueba';

  @override
  String get debugErrorSent => 'Error enviado a Crashlytics';

  @override
  String get debugCrash => 'Forzar cierre de la app (crash)';
}
