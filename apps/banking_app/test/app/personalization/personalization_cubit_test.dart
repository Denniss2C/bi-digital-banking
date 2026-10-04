import 'dart:async';

import 'package:auth/auth.dart';
import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fakes.dart';

/// Accounts whose segment the test controls.
class _SegmentAccounts extends FakeAccountsRepository {
  final segments = StreamController<Either<Failure, String>>.broadcast();

  @override
  Stream<Either<Failure, String>> watchSegment(String userId) =>
      segments.stream;
}

void main() {
  const saverHome = PersonalizationConfig(homeLayout: '{"components": []}');

  late FakeAuthRepository auth;
  late SessionCubit session;
  late _SegmentAccounts accounts;
  late FakePersonalizationSource source;
  late PersonalizationCubit cubit;

  setUp(() {
    auth = FakeAuthRepository(signedInUser: testUser);
    session = SessionCubit(auth);
    accounts = _SegmentAccounts();
    source = FakePersonalizationSource(bySegment: {'saver': saverHome});
    cubit = PersonalizationCubit(
      source: source,
      session: session,
      accounts: accounts,
    );
  });

  tearDown(() async {
    await cubit.close();
    await session.close();
    await accounts.segments.close();
  });

  // Lets the session, the stream events and the fetches complete.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts with the embedded values', () {
    expect(cubit.state, PersonalizationConfig.defaults);
  });

  test("applies the signed-in customer's segment", () async {
    await settle();
    accounts.segments.add(const Right('saver'));
    await settle();

    expect(source.segments, ['saver']);
    expect(cubit.state, saverHome);
  });

  test('the same segment is not fetched twice', () async {
    await settle();
    accounts.segments
      ..add(const Right('saver'))
      ..add(const Right('saver'));
    await settle();

    expect(source.segments, ['saver']);
  });

  test('a segment error keeps the current one', () async {
    await settle();
    accounts.segments
      ..add(const Right('saver'))
      ..add(const Left(NetworkFailure()));
    await settle();

    expect(source.segments, ['saver']);
    expect(cubit.state, saverHome);
  });

  test('a published update reaches the app while it runs', () async {
    await settle();
    source.publish(
      const PersonalizationConfig(flags: FeatureFlags(transfers: false)),
    );
    await settle();

    expect(cubit.state.flags.transfers, isFalse);
  });

  test('signing out unsets the segment', () async {
    await settle();
    accounts.segments.add(const Right('saver'));
    await settle();

    await auth.signOut();
    await settle();

    expect(source.segments, ['saver', null]);
  });

  test('refresh fetches and emits the active values', () async {
    await settle();
    source.current = saverHome;

    await cubit.refresh();

    expect(source.refreshes, 1);
    expect(cubit.state, saverHome);
  });
}
