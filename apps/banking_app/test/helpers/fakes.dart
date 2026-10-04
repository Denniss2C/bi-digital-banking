import 'dart:async';

import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/app.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:banking_app/app/observability/app_observability.dart';
import 'package:banking_app/app/personalization/personalization_config.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/app/personalization/personalization_source.dart';
import 'package:banking_app/app/push/push_coordinator.dart';
import 'package:banking_app/app/router/app_router.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:fx_rates/fx_rates.dart';
import 'package:notifications/notifications.dart';
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

/// Static accounts and movements for shell tests.
class FakeAccountsRepository implements AccountsRepository {
  FakeAccountsRepository({
    List<Account>? accounts,
    this.movements = const [],
    this.segment = 'new_user',
  }) : accounts =
           accounts ??
           const [
             Account(
               id: 'savings',
               type: AccountType.savings,
               alias: 'Cuenta de Ahorros',
               maskedNumber: '•••• 4892',
               balanceCents: 384550,
             ),
             Account(
               id: 'checking',
               type: AccountType.checking,
               alias: 'Cuenta Corriente',
               maskedNumber: '•••• 1035',
               balanceCents: 125000,
             ),
           ];

  final List<Account> accounts;
  final List<AccountTransaction> movements;
  final String segment;

  /// Transfers requested so far, in order.
  final transfers = <TransferReceipt>[];

  @override
  Stream<Either<Failure, AccountsSnapshot>> watchAccounts(String userId) =>
      Stream.value(
        Right(AccountsSnapshot(accounts: accounts, isFromCache: false)),
      );

  @override
  Future<Either<Failure, TransactionPage>> fetchTransactions({
    required String userId,
    required String accountId,
    TransactionCursor? after,
    int pageSize = 20,
  }) async => Right(
    // Only the first account has movements, so lists that merge accounts
    // (the home) do not repeat them.
    TransactionPage(
      items: accountId == accounts.first.id ? movements : const [],
    ),
  );

  @override
  Future<Either<Failure, Unit>> ensureOpeningData({
    required String userId,
    required String name,
    required String email,
  }) async => const Right(unit);

  @override
  Stream<Either<Failure, String>> watchSegment(String userId) =>
      Stream.value(Right(segment));

  /// Segments set so far, in order.
  final segmentsSet = <String>[];

  @override
  Future<Either<Failure, Unit>> setSegment({
    required String userId,
    required String segment,
  }) async {
    segmentsSet.add(segment);
    return const Right(unit);
  }

  @override
  String newTransferId() => 'transfer-${transfers.length + 1}';

  @override
  Future<Either<Failure, TransferReceipt>> transfer({
    required String userId,
    required String transferId,
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required String concept,
  }) async {
    final from = accounts.firstWhere((account) => account.id == fromAccountId);
    final receipt = TransferReceipt(
      transferId: transferId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amountCents: amountCents,
      concept: concept,
      createdAt: DateTime(2026, 10, 3, 9, 5),
      fromBalanceAfterCents: from.balanceCents - amountCents,
    );
    transfers.add(receipt);
    return Right(receipt);
  }
}

/// Remote Config stand-in: [bySegment] plays the role of the template's
/// conditions and [publish] the role of publishing in the console.
class FakePersonalizationSource implements PersonalizationSource {
  FakePersonalizationSource({
    this.current = PersonalizationConfig.defaults,
    Map<String, PersonalizationConfig>? bySegment,
  }) : bySegment = bySegment ?? {};

  @override
  PersonalizationConfig current;
  final Map<String, PersonalizationConfig> bySegment;

  /// Segments set so far, in order (`null` = unset).
  final segments = <String?>[];
  var refreshes = 0;
  final _updates = StreamController<PersonalizationConfig>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setSegment(String? segment) async {
    segments.add(segment);
    current = bySegment[segment] ?? current;
  }

  @override
  Future<void> refresh() async => refreshes++;

  @override
  Stream<PersonalizationConfig> get updates => _updates.stream;

  void publish(PersonalizationConfig config) {
    current = config;
    _updates.add(config);
  }
}

/// Exchange rates published on 2026-10-04 (no network).
class FakeFxRatesRepository implements FxRatesRepository {
  @override
  Stream<Either<Failure, FxSnapshot>> watchRates({bool forceRefresh = false}) =>
      Stream.value(
        Right(
          FxSnapshot(
            rates: FxRates(
              base: 'USD',
              rates: const {
                'USD': 1,
                'EUR': 0.8888,
                'COP': 3311.64,
                'PEN': 3.44,
              },
              updatedAt: DateTime.utc(2026, 10, 4),
              nextUpdateAt: DateTime.utc(2026, 10, 5),
            ),
            fetchedAt: DateTime.utc(2026, 10, 4, 15),
            source: FxSource.network,
          ),
        ),
      );
}

/// Push service whose messages and tokens the test drives.
class FakePushService implements PushService {
  FakePushService({this.currentToken = 'token-1', this.launchMessage});

  String? currentToken;

  /// The notification that "launched" the app, if any.
  PushMessage? launchMessage;
  var permissionRequests = 0;

  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  final refreshedTokens = StreamController<String>.broadcast();

  @override
  Future<PushPermission> requestPermission() async {
    permissionRequests++;
    return PushPermission.granted;
  }

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get tokenRefreshes => refreshedTokens.stream;

  @override
  Stream<PushMessage> get foregroundMessages => foreground.stream;

  @override
  Stream<PushMessage> get openedMessages => opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => launchMessage;
}

/// Records which tokens are saved and removed for each user.
class FakePushTokenRegistry implements PushTokenRegistry {
  final saved = <(String, String)>[];
  final removed = <(String, String)>[];

  @override
  Future<Either<Failure, Unit>> save({
    required String userId,
    required String token,
  }) async {
    saved.add((userId, token));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> remove({
    required String userId,
    required String token,
  }) async {
    removed.add((userId, token));
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
  FakeAccountsRepository? accountsRepository,
  PersonalizationSource? personalization,
  DebugTools? debugTools,
  FxRatesRepository? fxRatesRepository,
  FakePushService? push,
  RecordingTelemetry? telemetry,
}) async {
  final recorder = telemetry ?? RecordingTelemetry();
  tester.platformDispatcher.localesTestValue = deviceLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final onboarding = LocalOnboardingRepository(InMemoryKeyValueStore());
  if (hasSeenOnboarding) await onboarding.markOnboardingSeen();
  final auth = FakeAuthRepository(signedInUser: signedInUser);
  final session = SessionCubit(auth);
  // Closing a cubit inside testWidgets' fake clock never completes; close it
  // in the real event loop instead.
  addTearDown(() => tester.runAsync(session.close));
  final accounts =
      accountsRepository ??
      FakeAccountsRepository(
        movements: [
          AccountTransaction(
            id: 't1',
            type: TransactionType.debit,
            amountCents: 6430,
            description: 'Supermaxi Mall del Sol',
            category: 'groceries',
            createdAt: DateTime(2026, 9, 20, 11, 30),
            balanceAfterCents: 384550,
          ),
        ],
      );
  final personalizationCubit = PersonalizationCubit(
    source: personalization ?? FakePersonalizationSource(),
    session: session,
    accounts: accounts,
  );
  addTearDown(() => tester.runAsync(personalizationCubit.close));
  final router = createRouter(
    session: session,
    personalization: personalizationCubit,
    onboardingRepository: onboarding,
    authRepository: auth,
    accountsRepository: accounts,
    fxRatesRepository: fxRatesRepository ?? FakeFxRatesRepository(),
    telemetry: recorder,
    debugTools: debugTools,
  );
  addTearDown(router.dispose);
  final pushCoordinator = PushCoordinator(
    session: session,
    push: push ?? FakePushService(),
    tokens: FakePushTokenRegistry(),
    navigate: router.go,
    telemetry: recorder,
  );
  await pushCoordinator.start();
  addTearDown(() => tester.runAsync(pushCoordinator.dispose));
  final observability = AppObservability(
    telemetry: recorder,
    session: session,
    router: router,
  )..start();
  addTearDown(() => tester.runAsync(observability.dispose));

  await tester.pumpWidget(
    App(
      config: config,
      router: router,
      session: session,
      personalization: personalizationCubit,
      push: pushCoordinator,
    ),
  );
  await tester.pumpAndSettle();
}
