import 'package:accounts/accounts.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAccountsRepository repository;

  final receipt = TransferReceipt(
    transferId: 'tx-1',
    fromAccountId: 'savings',
    toAccountId: 'checking',
    amountCents: 5000,
    concept: '',
    createdAt: DateTime(2026, 10, 3),
    fromBalanceAfterCents: 379550,
  );

  setUp(() {
    repository = MockAccountsRepository();
    when(() => repository.newTransferId()).thenReturn('tx-1');
    when(() => repository.watchAccounts('u')).thenAnswer(
      (_) => Stream.value(
        const Right(
          AccountsSnapshot(accounts: [savings, checking], isFromCache: false),
        ),
      ),
    );
  });

  void stubTransfer(Either<Failure, TransferReceipt> result) => when(
    () => repository.transfer(
      userId: any(named: 'userId'),
      transferId: any(named: 'transferId'),
      fromAccountId: any(named: 'fromAccountId'),
      toAccountId: any(named: 'toAccountId'),
      amountCents: any(named: 'amountCents'),
      concept: any(named: 'concept'),
    ),
  ).thenAnswer((_) async => result);

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onDone,
    Telemetry telemetry = const NoopTelemetry(),
  }) => tester.pumpLocalized(
    TransferPage(
      repository: repository,
      userId: 'u',
      onDone: onDone ?? () {},
      telemetry: telemetry,
    ),
  );

  final sendButton = find.widgetWithText(AppButton, 'Transferir');

  Future<void> send(WidgetTester tester) async {
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapChip(WidgetTester tester, String amount) async {
    await tester.tap(find.widgetWithText(ActionChip, amount));
    await tester.pumpAndSettle();
  }

  testWidgets('preselects both accounts and fills the amount from a chip', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(r'Cuenta de Ahorros · $3,845.50'), findsOneWidget);
    expect(find.text(r'Disponible en tu cuenta: $3,845.50'), findsOneWidget);
    expect(
      find.text(r'Costo de la transferencia: $0.00 · acreditación inmediata'),
      findsOneWidget,
    );

    await tapChip(tester, r'$50.00');

    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('sending without an amount explains why and sends nothing', (
    tester,
  ) async {
    await pump(tester);

    await send(tester);

    expect(find.text('Ingresa un monto válido'), findsOneWidget);
    verifyNever(
      () => repository.transfer(
        userId: any(named: 'userId'),
        transferId: any(named: 'transferId'),
        fromAccountId: any(named: 'fromAccountId'),
        toAccountId: any(named: 'toAccountId'),
        amountCents: any(named: 'amountCents'),
        concept: any(named: 'concept'),
      ),
    );
  });

  testWidgets('the same account on both sides asks for another one', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuenta de Ahorros').last);
    await tester.pumpAndSettle();
    await tapChip(tester, r'$20.00');
    await send(tester);

    expect(
      find.text('Elige una cuenta distinta a la de origen'),
      findsOneWidget,
    );
  });

  testWidgets('a successful transfer shows the receipt and can start over', (
    tester,
  ) async {
    stubTransfer(Right(receipt));
    var done = 0;
    await pump(tester, onDone: () => done++);

    await tapChip(tester, r'$50.00');
    await send(tester);

    expect(find.text('Transferencia exitosa'), findsOneWidget);
    expect(
      find.text(r'$50.00 de Cuenta de Ahorros a Cuenta Corriente'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver mis cuentas'));
    expect(done, 1);

    await tester.tap(find.text('Nueva transferencia'));
    await tester.pumpAndSettle();

    expect(sendButton, findsOneWidget);
    expect(find.text('50'), findsNothing);
  });

  for (final (failure, message) in [
    (
      const NetworkFailure(),
      'Sin conexión. Las transferencias necesitan internet; inténtalo de '
          'nuevo.',
    ),
    (
      const ValidationFailure(code: 'insufficientFunds'),
      'Saldo insuficiente en la cuenta de origen',
    ),
  ]) {
    testWidgets('a ${failure.runtimeType} keeps the form with a message', (
      tester,
    ) async {
      stubTransfer(Left(failure));
      await pump(tester);

      await tapChip(tester, r'$50.00');
      await send(tester);

      expect(find.text(message), findsOneWidget);
      expect(sendButton, findsOneWidget);
    });
  }

  testWidgets('accounts that cannot load offer a way back', (tester) async {
    when(
      () => repository.watchAccounts('u'),
    ).thenAnswer((_) => Stream.value(const Left(NetworkFailure())));
    var done = 0;
    await pump(tester, onDone: () => done++);

    expect(find.text('No pudimos cargar tus cuentas'), findsOneWidget);
    await tester.tap(find.text('Ver mis cuentas'));
    expect(done, 1);
  });

  test('an unknown rule code falls back to the generic message', () {
    final l10n = lookupAccountsLocalizations(const Locale('es'));

    expect(
      transferFailureMessage(l10n, const ValidationFailure(code: 'nope')),
      'Ocurrió un problema. Inténtalo de nuevo.',
    );
    expect(
      transferFailureMessage(l10n, const ServerFailure()),
      'Ocurrió un problema. Inténtalo de nuevo.',
    );
  });

  group('telemetry', () {
    testWidgets('a successful transfer is reported with its duration', (
      tester,
    ) async {
      stubTransfer(Right(receipt));
      final telemetry = RecordingTelemetry();
      await pump(tester, telemetry: telemetry);

      await tapChip(tester, r'$50.00');
      await send(tester);

      expect(telemetry.eventNames, ['transfer_completed']);
      final trace = telemetry.traces.single;
      expect(trace.name, 'transfer_submit');
      expect(trace.stopped, isTrue);
      expect(trace.attributes, {'result': 'success'});
    });

    testWidgets('a failed transfer reports the reason, never the amount', (
      tester,
    ) async {
      stubTransfer(const Left(ValidationFailure(code: 'insufficientFunds')));
      final telemetry = RecordingTelemetry();
      await pump(tester, telemetry: telemetry);

      await tapChip(tester, r'$50.00');
      await send(tester);

      expect(telemetry.eventNames, ['transfer_failed']);
      expect(telemetry.events.single.$2, {'reason': 'insufficientFunds'});
      expect(telemetry.traces.single.stopped, isTrue);
    });

    testWidgets('an invalid form is not a transfer attempt', (tester) async {
      final telemetry = RecordingTelemetry();
      await pump(tester, telemetry: telemetry);

      await send(tester);

      expect(telemetry.events, isEmpty);
      expect(telemetry.traces, isEmpty);
    });
  });
}
