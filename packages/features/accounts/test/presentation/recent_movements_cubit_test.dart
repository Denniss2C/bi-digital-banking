import 'dart:async';

import 'package:accounts/accounts.dart';
import 'package:accounts/src/presentation/recent_movements/recent_movements_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAccountsRepository repository;
  late StreamController<Either<Failure, AccountsSnapshot>> accounts;

  AccountTransaction at(String id, int day) => AccountTransaction(
    id: id,
    type: TransactionType.debit,
    amountCents: 100,
    description: id,
    category: 'groceries',
    createdAt: DateTime(2026, 9, day),
    balanceAfterCents: 1000,
  );

  void stubMovements(String accountId, List<AccountTransaction> items) => when(
    () => repository.fetchTransactions(
      userId: 'u',
      accountId: accountId,
      pageSize: any(named: 'pageSize'),
    ),
  ).thenAnswer((_) async => Right(TransactionPage(items: items)));

  Right<Failure, AccountsSnapshot> snapshot(List<Account> list) =>
      Right(AccountsSnapshot(accounts: list, isFromCache: false));

  setUp(() {
    repository = MockAccountsRepository();
    // Broadcast: close() completes even if a test never listens to it.
    accounts = StreamController.broadcast();
    when(
      () => repository.watchAccounts('u'),
    ).thenAnswer((_) => accounts.stream);
    stubMovements('savings', [at('s1', 3), at('s2', 1)]);
    stubMovements('checking', [at('c1', 2), at('c2', 4)]);
  });

  tearDown(() => accounts.close());

  RecentMovementsCubit build({int limit = 3}) =>
      RecentMovementsCubit(repository: repository, userId: 'u', limit: limit);

  // Lets the stream event and the fetches complete.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  blocTest<RecentMovementsCubit, RecentMovementsState>(
    'merges all the accounts, newest first, up to the limit',
    build: build,
    act: (_) async {
      accounts.add(snapshot([savings, checking]));
      await settle();
    },
    expect: () => [
      RecentMovementsLoaded(
        items: [at('c2', 4), at('s1', 3), at('c1', 2)],
        isFromCache: false,
      ),
    ],
  );

  blocTest<RecentMovementsCubit, RecentMovementsState>(
    'fetches again only when a balance changes',
    build: build,
    act: (_) async {
      accounts.add(snapshot([savings, checking]));
      await settle();
      // Same balances (e.g. a metadata-only update): no new fetch.
      accounts.add(snapshot([savings, checking]));
      await settle();
      final afterTransfer = Account(
        id: savings.id,
        type: savings.type,
        alias: savings.alias,
        maskedNumber: savings.maskedNumber,
        balanceCents: savings.balanceCents - 100,
      );
      accounts.add(snapshot([afterTransfer, checking]));
      await settle();
    },
    verify: (_) => verify(
      () => repository.fetchTransactions(
        userId: 'u',
        accountId: 'savings',
        pageSize: 3,
      ),
    ).called(2),
  );

  blocTest<RecentMovementsCubit, RecentMovementsState>(
    'a failed fetch is an error that can be retried',
    setUp: () {
      var calls = 0;
      when(
        () => repository.fetchTransactions(
          userId: 'u',
          accountId: 'savings',
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => calls++ == 0
            ? const Left(NetworkFailure())
            : Right(TransactionPage(items: [at('s1', 3)])),
      );
      when(
        () => repository.watchAccounts('u'),
      ).thenAnswer((_) => Stream.value(snapshot([savings])));
    },
    build: build,
    act: (cubit) async {
      await settle();
      cubit.retry();
      await settle();
    },
    expect: () => [
      const RecentMovementsError(NetworkFailure()),
      const RecentMovementsLoading(),
      RecentMovementsLoaded(items: [at('s1', 3)], isFromCache: false),
    ],
  );

  blocTest<RecentMovementsCubit, RecentMovementsState>(
    'cached pages are reported as offline data',
    setUp: () =>
        when(
          () => repository.fetchTransactions(
            userId: 'u',
            accountId: 'savings',
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(TransactionPage(items: [at('s1', 3)], isFromCache: true)),
        ),
    build: build,
    act: (_) async {
      accounts.add(snapshot([savings]));
      await settle();
    },
    expect: () => [
      RecentMovementsLoaded(items: [at('s1', 3)], isFromCache: true),
    ],
  );

  test('an older fetch that finishes last is ignored', () async {
    final slow = Completer<Either<Failure, TransactionPage>>();
    var calls = 0;
    when(
      () => repository.fetchTransactions(
        userId: 'u',
        accountId: 'savings',
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) => calls++ == 0
          ? slow.future
          : Future.value(Right(TransactionPage(items: [at('new', 5)]))),
    );
    final cubit = build();
    addTearDown(cubit.close);

    accounts.add(snapshot([savings]));
    await settle();
    final afterTransfer = Account(
      id: savings.id,
      type: savings.type,
      alias: savings.alias,
      maskedNumber: savings.maskedNumber,
      balanceCents: savings.balanceCents - 100,
    );
    accounts.add(snapshot([afterTransfer]));
    await settle();
    slow.complete(Right(TransactionPage(items: [at('old', 1)])));
    await settle();

    expect(
      cubit.state,
      RecentMovementsLoaded(items: [at('new', 5)], isFromCache: false),
    );
  });

  blocTest<RecentMovementsCubit, RecentMovementsState>(
    'an accounts error after loading keeps the movements',
    build: build,
    act: (_) async {
      accounts
        ..add(snapshot([savings, checking]))
        ..add(const Left(NetworkFailure()));
      await settle();
    },
    verify: (cubit) => expect(cubit.state, isA<RecentMovementsLoaded>()),
  );
}
