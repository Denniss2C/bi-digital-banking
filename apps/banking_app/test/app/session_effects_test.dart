import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/session_effects.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../helpers/fakes.dart';

class _RecordingAccounts implements AccountsRepository {
  final calls = <(String, String, String)>[];

  @override
  Future<Either<Failure, Unit>> ensureOpeningData({
    required String userId,
    required String name,
    required String email,
  }) async {
    calls.add((userId, name, email));
    return const Right(unit);
  }

  @override
  Stream<Either<Failure, AccountsSnapshot>> watchAccounts(String userId) =>
      const Stream.empty();

  @override
  Stream<Either<Failure, String>> watchSegment(String userId) =>
      const Stream.empty();

  @override
  Future<Either<Failure, Unit>> setSegment({
    required String userId,
    required String segment,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, TransactionPage>> fetchTransactions({
    required String userId,
    required String accountId,
    TransactionCursor? after,
    int pageSize = 20,
  }) async => const Right(TransactionPage(items: []));

  @override
  String newTransferId() => 'transfer-1';

  @override
  Future<Either<Failure, TransferReceipt>> transfer({
    required String userId,
    required String transferId,
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required String concept,
  }) async => const Left(NetworkFailure());
}

void main() {
  test(
    'prepares the opening data on sign-in, once per user and name',
    () async {
      final auth = FakeAuthRepository();
      final session = SessionCubit(auth);
      final accounts = _RecordingAccounts();
      final effects = SessionEffects(session: session, accounts: accounts);
      addTearDown(() async {
        await effects.dispose();
        await session.close();
      });

      await auth.signUp(name: 'Mateo', email: 'm@nexo.ec', password: 'x');
      await pumpEventQueue();
      expect(accounts.calls, [('uid-1', 'Mateo', 'm@nexo.ec')]);

      await auth.signOut();
      await pumpEventQueue();
      expect(accounts.calls, hasLength(1), reason: 'signing out does nothing');

      await auth.signIn(email: 'm@nexo.ec', password: 'x');
      await pumpEventQueue();
      expect(accounts.calls, hasLength(2), reason: 'a new session runs again');
    },
  );

  test('a stored session at startup is prepared immediately', () async {
    final session = SessionCubit(FakeAuthRepository(signedInUser: testUser));
    await pumpEventQueue();
    final accounts = _RecordingAccounts();
    final effects = SessionEffects(session: session, accounts: accounts);
    addTearDown(() async {
      await effects.dispose();
      await session.close();
    });

    expect(accounts.calls, [('uid-1', 'Mateo Moreno', 'mateo@nexo.ec')]);
  });
}
