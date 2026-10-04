import 'package:accounts/accounts.dart';
import 'package:accounts/src/presentation/accounts/accounts_cubit.dart';
import 'package:accounts/src/presentation/transactions/transactions_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAccountsRepository repository;

  setUp(() => repository = MockAccountsRepository());

  group('AccountsCubit', () {
    blocTest<AccountsCubit, AccountsState>(
      'emits the accounts and the cache flag',
      setUp: () => when(() => repository.watchAccounts('u')).thenAnswer(
        (_) => Stream.value(
          const Right(
            AccountsSnapshot(accounts: [savings, checking], isFromCache: true),
          ),
        ),
      ),
      build: () => AccountsCubit(repository: repository, userId: 'u'),
      expect: () => [
        const AccountsLoaded(accounts: [savings, checking], isFromCache: true),
      ],
      verify: (cubit) =>
          expect((cubit.state as AccountsLoaded).totalCents, 440050),
    );

    blocTest<AccountsCubit, AccountsState>(
      'an error can be retried',
      setUp: () {
        var calls = 0;
        when(() => repository.watchAccounts('u')).thenAnswer(
          (_) => Stream.value(
            calls++ == 0
                ? const Left(NetworkFailure())
                : const Right(
                    AccountsSnapshot(accounts: [savings], isFromCache: false),
                  ),
          ),
        );
      },
      build: () => AccountsCubit(repository: repository, userId: 'u'),
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        cubit.retry();
      },
      expect: () => [
        const AccountsError(NetworkFailure()),
        const AccountsLoading(),
        const AccountsLoaded(accounts: [savings], isFromCache: false),
      ],
    );
  });

  group('TransactionsCubit', () {
    TransactionsCubit build() => TransactionsCubit(
      repository: repository,
      userId: 'u',
      accountId: 'savings',
      pageSize: 2,
    );

    void stubPage(
      Either<Failure, TransactionPage> result, {
      TransactionCursor? after,
    }) {
      when(
        () => repository.fetchTransactions(
          userId: 'u',
          accountId: 'savings',
          after: after,
          pageSize: 2,
        ),
      ).thenAnswer((_) async => result);
    }

    const cursor = TransactionCursor('after-t1');

    blocTest<TransactionsCubit, TransactionsState>(
      'loads the first page',
      setUp: () => stubPage(
        Right(TransactionPage(items: [movement(0), movement(1)], next: cursor)),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const TransactionsState(),
        TransactionsState(
          status: TransactionsStatus.success,
          items: [movement(0), movement(1)],
          hasMore: true,
        ),
      ],
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'a failed first page shows the error',
      setUp: () => stubPage(const Left(NetworkFailure())),
      build: build,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        const TransactionsState(
          status: TransactionsStatus.failure,
          failure: NetworkFailure(),
        ),
      ],
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'loadMore appends the next page and stops at the end',
      setUp: () {
        stubPage(
          Right(
            TransactionPage(items: [movement(0), movement(1)], next: cursor),
          ),
        );
        stubPage(Right(TransactionPage(items: [movement(2)])), after: cursor);
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
        await cubit.loadMore(); // no more pages: ignored
      },
      skip: 2,
      expect: () => [
        TransactionsState(
          status: TransactionsStatus.success,
          items: [movement(0), movement(1)],
          hasMore: true,
          isLoadingMore: true,
        ),
        TransactionsState(
          status: TransactionsStatus.success,
          items: [movement(0), movement(1), movement(2)],
        ),
      ],
    );

    blocTest<TransactionsCubit, TransactionsState>(
      'a failed loadMore keeps the items and flags the error',
      setUp: () {
        stubPage(
          Right(
            TransactionPage(items: [movement(0), movement(1)], next: cursor),
          ),
        );
        stubPage(const Left(NetworkFailure()), after: cursor);
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 3,
      expect: () => [
        TransactionsState(
          status: TransactionsStatus.success,
          items: [movement(0), movement(1)],
          hasMore: true,
          loadMoreFailed: true,
        ),
      ],
    );
  });
}
