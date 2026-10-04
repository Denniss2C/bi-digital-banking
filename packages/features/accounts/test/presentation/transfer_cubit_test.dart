import 'dart:async';

import 'package:accounts/accounts.dart';
import 'package:accounts/src/presentation/transfer/transfer_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAccountsRepository repository;

  const loaded = TransferState(
    status: TransferStatus.editing,
    accounts: [savings, checking],
    fromId: 'savings',
    toId: 'checking',
  );

  final receipt = TransferReceipt(
    transferId: 'tx-1',
    fromAccountId: 'savings',
    toAccountId: 'checking',
    amountCents: 5000,
    concept: 'Ahorro',
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

  void verifyNoTransfer() => verifyNever(
    () => repository.transfer(
      userId: any(named: 'userId'),
      transferId: any(named: 'transferId'),
      fromAccountId: any(named: 'fromAccountId'),
      toAccountId: any(named: 'toAccountId'),
      amountCents: any(named: 'amountCents'),
      concept: any(named: 'concept'),
    ),
  );

  TransferCubit build() => TransferCubit(repository: repository, userId: 'u');

  // Lets the first accounts snapshot arrive.
  Future<void> accountsLoaded() => Future<void>.delayed(Duration.zero);

  blocTest<TransferCubit, TransferState>(
    'loads the accounts, from the first one to the second one',
    build: build,
    expect: () => [loaded],
  );

  blocTest<TransferCubit, TransferState>(
    'an error loading the accounts is a failure',
    setUp: () => when(
      () => repository.watchAccounts('u'),
    ).thenAnswer((_) => Stream.value(const Left(NetworkFailure()))),
    build: build,
    expect: () => [
      const TransferState(
        status: TransferStatus.failure,
        failure: NetworkFailure(),
      ),
    ],
  );

  blocTest<TransferCubit, TransferState>(
    'an invalid form only reveals the errors',
    build: build,
    act: (cubit) async {
      await accountsLoaded();
      await cubit.submit();
    },
    expect: () => [loaded, loaded.copyWith(showErrors: true)],
    verify: (cubit) {
      expect(cubit.state.validationError, TransferError.invalidAmount);
      verifyNoTransfer();
    },
  );

  blocTest<TransferCubit, TransferState>(
    'more than the available balance is caught before sending',
    build: build,
    act: (cubit) async {
      await accountsLoaded();
      cubit.amountChanged('3845.51');
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.validationError, TransferError.insufficientFunds);
      verifyNoTransfer();
    },
  );

  blocTest<TransferCubit, TransferState>(
    'a valid transfer ends with the receipt',
    setUp: () => stubTransfer(Right(receipt)),
    build: build,
    act: (cubit) async {
      await accountsLoaded();
      cubit
        ..amountChanged('50')
        ..conceptChanged(' Ahorro ');
      await cubit.submit();
    },
    expect: () {
      final filled = loaded.copyWith(amountText: '50', concept: ' Ahorro ');
      return [
        loaded,
        loaded.copyWith(amountText: '50'),
        filled,
        filled.copyWith(status: TransferStatus.submitting, showErrors: true),
        filled.copyWith(
          status: TransferStatus.success,
          showErrors: true,
          receipt: receipt,
        ),
      ];
    },
    verify: (_) => verify(
      () => repository.transfer(
        userId: 'u',
        transferId: 'tx-1',
        fromAccountId: 'savings',
        toAccountId: 'checking',
        amountCents: 5000,
        concept: 'Ahorro',
      ),
    ).called(1),
  );

  blocTest<TransferCubit, TransferState>(
    'a second tap while sending is ignored',
    setUp: () => stubTransfer(Right(receipt)),
    build: build,
    act: (cubit) async {
      await accountsLoaded();
      cubit.amountChanged('50');
      await Future.wait([cubit.submit(), cubit.submit()]);
    },
    verify: (_) => verify(
      () => repository.transfer(
        userId: any(named: 'userId'),
        transferId: any(named: 'transferId'),
        fromAccountId: any(named: 'fromAccountId'),
        toAccountId: any(named: 'toAccountId'),
        amountCents: any(named: 'amountCents'),
        concept: any(named: 'concept'),
      ),
    ).called(1),
  );

  blocTest<TransferCubit, TransferState>(
    'a rejected transfer keeps the form, and editing clears the error',
    setUp: () => stubTransfer(const Left(NetworkFailure())),
    build: build,
    act: (cubit) async {
      await accountsLoaded();
      cubit.amountChanged('50');
      await cubit.submit();
      cubit.amountChanged('40');
    },
    skip: 3,
    expect: () {
      final filled = loaded.copyWith(amountText: '50', showErrors: true);
      return [
        filled.copyWith(
          status: TransferStatus.failure,
          failure: const NetworkFailure(),
        ),
        filled.copyWith(amountText: '40'),
      ];
    },
  );

  blocTest<TransferCubit, TransferState>(
    'a new transfer keeps the accounts and clears the form',
    setUp: () => stubTransfer(Right(receipt)),
    build: build,
    act: (cubit) async {
      await accountsLoaded();
      cubit
        ..toChanged('savings')
        ..fromChanged('checking')
        ..amountChanged('5');
      await cubit.submit();
      cubit.restart();
    },
    verify: (cubit) => expect(
      cubit.state,
      loaded.copyWith(fromId: 'checking', toId: 'savings'),
    ),
  );

  group('idempotency key', () {
    late List<Either<Failure, TransferReceipt>> answers;

    setUp(() {
      var ids = 0;
      when(() => repository.newTransferId()).thenAnswer((_) => 'id-${++ids}');
      when(
        () => repository.transfer(
          userId: any(named: 'userId'),
          transferId: any(named: 'transferId'),
          fromAccountId: any(named: 'fromAccountId'),
          toAccountId: any(named: 'toAccountId'),
          amountCents: any(named: 'amountCents'),
          concept: any(named: 'concept'),
        ),
      ).thenAnswer((_) async => answers.removeAt(0));
    });

    List<dynamic> sentIds() => verify(
      () => repository.transfer(
        userId: any(named: 'userId'),
        transferId: captureAny(named: 'transferId'),
        fromAccountId: any(named: 'fromAccountId'),
        toAccountId: any(named: 'toAccountId'),
        amountCents: any(named: 'amountCents'),
        concept: any(named: 'concept'),
      ),
    ).captured;

    blocTest<TransferCubit, TransferState>(
      'a retry after a failure sends the same transfer id',
      setUp: () => answers = [const Left(NetworkFailure()), Right(receipt)],
      build: build,
      act: (cubit) async {
        await accountsLoaded();
        cubit.amountChanged('50');
        await cubit.submit();
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, TransferStatus.success);
        expect(sentIds(), ['id-1', 'id-1']);
      },
    );

    blocTest<TransferCubit, TransferState>(
      'a change after a failure, or a new transfer, gets a new id',
      setUp: () => answers = [
        const Left(NetworkFailure()),
        Right(receipt),
        Right(receipt),
      ],
      build: build,
      act: (cubit) async {
        await accountsLoaded();
        cubit.amountChanged('50');
        await cubit.submit();
        cubit.amountChanged('40');
        await cubit.submit();
        cubit
          ..restart()
          ..amountChanged('10');
        await cubit.submit();
      },
      verify: (_) => expect(sentIds(), ['id-1', 'id-2', 'id-3']),
    );
  });

  test('leaving the screen while sending does not throw', () async {
    final response = Completer<Either<Failure, TransferReceipt>>();
    when(
      () => repository.transfer(
        userId: any(named: 'userId'),
        transferId: any(named: 'transferId'),
        fromAccountId: any(named: 'fromAccountId'),
        toAccountId: any(named: 'toAccountId'),
        amountCents: any(named: 'amountCents'),
        concept: any(named: 'concept'),
      ),
    ).thenAnswer((_) => response.future);
    final cubit = build();
    await accountsLoaded();
    cubit.amountChanged('50');

    final sending = cubit.submit();
    await cubit.close();
    response.complete(Right(receipt));

    await expectLater(sending, completes);
  });

  test('live balance updates keep the chosen accounts', () async {
    final accounts = StreamController<Either<Failure, AccountsSnapshot>>();
    when(
      () => repository.watchAccounts('u'),
    ).thenAnswer((_) => accounts.stream);
    final cubit = build();
    addTearDown(cubit.close);

    accounts.add(
      const Right(
        AccountsSnapshot(accounts: [savings, checking], isFromCache: false),
      ),
    );
    await accountsLoaded();
    cubit
      ..fromChanged('checking')
      ..toChanged('savings');
    final richer = Account(
      id: checking.id,
      type: checking.type,
      alias: checking.alias,
      maskedNumber: checking.maskedNumber,
      balanceCents: 99900,
    );
    accounts.add(
      Right(AccountsSnapshot(accounts: [savings, richer], isFromCache: false)),
    );
    await accountsLoaded();

    expect(cubit.state.fromId, 'checking');
    expect(cubit.state.toId, 'savings');
    expect(cubit.state.from?.balanceCents, 99900);
    await accounts.close();
  });
}
