// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'fx_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class FxLocalizationsEs extends FxLocalizations {
  FxLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get fxTitle => 'Divisas';

  @override
  String get fxSubtitle =>
      'Ecuador (USD). Tasas de referencia del mercado, sin margen de compra o venta.';

  @override
  String get statusLive => 'Tasas al día';

  @override
  String get statusOffline => 'Sin conexión';

  @override
  String get converterTitle => 'Cotizador';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get youHave => 'Tú tienes';

  @override
  String get youGet => 'Recibes aproximadamente';

  @override
  String get swapDirection => 'Invertir la conversión';

  @override
  String get invalidAmount => 'Ingresa un monto válido';

  @override
  String rateLine(String rate, String code) {
    return '1 USD = $rate $code';
  }

  @override
  String get referenceRateNote =>
      'Tasa media de mercado: no es una cotización de compra o venta.';

  @override
  String get ratesTitle => 'Tasas de referencia';

  @override
  String get updatedJustNow => 'Actualizado hace un momento';

  @override
  String updatedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Actualizado hace $count minutos',
      one: 'Actualizado hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String updatedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Actualizado hace $count horas',
      one: 'Actualizado hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String updatedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Actualizado hace $count días',
      one: 'Actualizado hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get refreshing => 'Actualizando…';

  @override
  String get offlineNotice =>
      'Sin conexión · mostrando las últimas tasas guardadas';

  @override
  String get staleNotice =>
      'No pudimos actualizar · mostrando las últimas tasas guardadas';

  @override
  String get errorTitle => 'No pudimos cargar las tasas';

  @override
  String get errorNetworkMessage => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get errorGenericMessage => 'Ocurrió un problema. Inténtalo de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get attribution => 'Rates By Exchange Rate API · exchangerate-api.com';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'USD': 'Dólar estadounidense',
      'EUR': 'Euro',
      'COP': 'Peso colombiano',
      'PEN': 'Sol peruano',
      'MXN': 'Peso mexicano',
      'BRL': 'Real brasileño',
      'CLP': 'Peso chileno',
      'ARS': 'Peso argentino',
      'GBP': 'Libra esterlina',
      'CAD': 'Dólar canadiense',
      'JPY': 'Yen japonés',
      'CNY': 'Yuan chino',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get widgetTitle => 'Mercado de divisas';

  @override
  String get widgetOpen => 'Abrir cotizador';
}
