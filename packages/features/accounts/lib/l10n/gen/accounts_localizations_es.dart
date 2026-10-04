// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'accounts_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AccountsLocalizationsEs extends AccountsLocalizations {
  AccountsLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get accountsTitle => 'Cuentas';

  @override
  String get totalBalanceLabel => 'Saldo total disponible';

  @override
  String accountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuentas',
      one: '1 cuenta',
    );
    return '$_temp0';
  }

  @override
  String get savingsType => 'Ahorros';

  @override
  String get checkingType => 'Corriente';

  @override
  String get availableBalance => 'Saldo disponible';

  @override
  String accountCardSemantics(String alias, String number, String amount) {
    return '$alias, $number, saldo disponible $amount';
  }

  @override
  String get accountsLoading => 'Cargando tus cuentas';

  @override
  String get accountsEmptyTitle => 'Estamos preparando tus cuentas';

  @override
  String get accountsEmptyMessage => 'En unos segundos verás tus cuentas aquí.';

  @override
  String get accountsErrorTitle => 'No pudimos cargar tus cuentas';

  @override
  String get movementsTitle => 'Movimientos';

  @override
  String get movementsLoading => 'Cargando movimientos';

  @override
  String get movementsEmptyTitle => 'Aún no tienes movimientos';

  @override
  String get movementsErrorTitle => 'No pudimos cargar tus movimientos';

  @override
  String get loadMoreError => 'No pudimos cargar más movimientos.';

  @override
  String get errorNetworkMessage => 'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get errorGenericMessage => 'Ocurrió un problema. Inténtalo de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get offlineNotice =>
      'Sin conexión · mostrando tus últimos datos guardados';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String creditSemantics(String amount) {
    return 'ingreso de $amount';
  }

  @override
  String debitSemantics(String amount) {
    return 'gasto de $amount';
  }

  @override
  String get transferAction => 'Transferir';

  @override
  String get transferTitle => 'Transferir dinero';

  @override
  String get transferToOwnAccounts => 'A cuentas Nexo · gratis e inmediato';

  @override
  String get fromLabel => 'Desde';

  @override
  String get toLabel => 'Para';

  @override
  String accountOption(String alias, String amount) {
    return '$alias · $amount';
  }

  @override
  String get amountLabel => 'Monto a enviar (USD)';

  @override
  String availableInAccount(String amount) {
    return 'Disponible en tu cuenta: $amount';
  }

  @override
  String get conceptLabel => 'Concepto o detalle (opcional)';

  @override
  String get transferCost =>
      'Costo de la transferencia: \$0.00 · acreditación inmediata';

  @override
  String get errorSameAccount => 'Elige una cuenta distinta a la de origen';

  @override
  String get errorInvalidAmount => 'Ingresa un monto válido';

  @override
  String errorLimitExceeded(String amount) {
    return 'El máximo por transferencia es $amount';
  }

  @override
  String errorConceptTooLong(int max) {
    return 'Usa máximo $max caracteres';
  }

  @override
  String get errorInsufficientFunds =>
      'Saldo insuficiente en la cuenta de origen';

  @override
  String get errorAccountNotFound => 'La cuenta ya no está disponible';

  @override
  String get errorTransferOffline =>
      'Sin conexión. Las transferencias necesitan internet; inténtalo de nuevo.';

  @override
  String get transferSuccessTitle => 'Transferencia exitosa';

  @override
  String transferSuccessMessage(String amount, String from, String to) {
    return '$amount de $from a $to';
  }

  @override
  String get newTransfer => 'Nueva transferencia';

  @override
  String get backToAccounts => 'Ver mis cuentas';

  @override
  String get seeAll => 'Ver todos';

  @override
  String get recentMovementsTitle => 'Movimientos recientes';
}
