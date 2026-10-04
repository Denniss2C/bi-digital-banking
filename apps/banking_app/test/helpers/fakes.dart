import 'dart:async';

import 'package:auth/auth.dart';
import 'package:banking_app/app/app.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/router/app_router.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const testUser = AppUser(
  id: 'uid-1',
  email: 'mateo@nexo.ec',
  displayName: 'Mateo Moreno',
);

/// In-memory auth that behaves like Firebase: `userChanges` emits the
/// current user on listen and every change afterwards.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedInUser}) : _current = signedInUser;

  AppUser? _current;
  final _changes = StreamController<AppUser?>.broadcast();

  void _set(AppUser? user) {
    _current = user;
    _changes.add(user);
  }

  // Stream.multi instead of an async* generator: cancelling a generator
  // suspended in `yield*` never completes inside testWidgets' fake clock,
  // which hung every test in its tearDown (SessionCubit.close).
  @override
  Stream<AppUser?> userChanges() => Stream.multi((controller) {
    controller.add(_current);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  AppUser? get currentUser => _current;

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    final user = AppUser(id: 'uid-1', email: email.trim());
    _set(user);
    return Right(user);
  }

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = AppUser(id: 'uid-1', email: email.trim(), displayName: name);
    _set(user);
    return Right(user);
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordReset({
    required String email,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> signOut() async {
    _set(null);
    return const Right(unit);
  }
}

class InMemoryKeyValueStore implements KeyValueStore {
  final _values = <String, Object?>{};

  @override
  T? read<T>(String key) => _values[key] as T?;

  @override
  Future<void> write<T>(String key, T value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// Pumps the whole app shell with fake auth and an in-memory store.
Future<void> pumpApp(
  WidgetTester tester, {
  AppUser? signedInUser,
  bool hasSeenOnboarding = false,
  AppConfig config = AppConfig.prod,
  List<Locale> deviceLocales = const [Locale('es', 'EC')],
}) async {
  tester.platformDispatcher.localesTestValue = deviceLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final onboarding = LocalOnboardingRepository(InMemoryKeyValueStore());
  if (hasSeenOnboarding) await onboarding.markOnboardingSeen();
  final auth = FakeAuthRepository(signedInUser: signedInUser);
  final session = SessionCubit(auth);
  // Closing a cubit inside testWidgets' fake clock never completes; close it
  // in the real event loop instead.
  addTearDown(() => tester.runAsync(session.close));
  final router = createRouter(
    session: session,
    onboardingRepository: onboarding,
    authRepository: auth,
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    App(config: config, router: router, session: session),
  );
  await tester.pumpAndSettle();
}
