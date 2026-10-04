import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/app/personalization/personalization_source.dart';
import 'package:banking_app/app/push/push_coordinator.dart';
import 'package:banking_app/app/router/app_router.dart';
import 'package:banking_app/app/session_effects.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:fx_rates/fx_rates.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:notifications/notifications.dart';

/// Objects the shell owns or composes from the features.
@module
abstract class AppModule {
  @lazySingleton
  AuthRepository get authRepository => FirebaseAuthRepository.instance();

  @lazySingleton
  OnboardingRepository onboardingRepository(KeyValueStore store) =>
      LocalOnboardingRepository(store);

  @lazySingleton
  SessionCubit sessionCubit(AuthRepository repository) =>
      SessionCubit(repository);

  @lazySingleton
  AccountsRepository get accountsRepository =>
      FirestoreAccountsRepository.instance();

  @lazySingleton
  SessionEffects sessionEffects(
    SessionCubit session,
    AccountsRepository accounts,
  ) => SessionEffects(session: session, accounts: accounts);

  @lazySingleton
  PersonalizationCubit personalizationCubit(
    AppConfig config,
    SessionCubit session,
    AccountsRepository accounts,
  ) => PersonalizationCubit(
    source: RemoteConfigPersonalizationSource(
      FirebaseRemoteConfig.instance,
      minimumFetchInterval: config.remoteConfigFetchInterval,
    ),
    session: session,
    accounts: accounts,
  );

  @lazySingleton
  PushService get pushService =>
      FirebasePushService(FirebaseMessaging.instance);

  @lazySingleton
  PushTokenRegistry get pushTokenRegistry =>
      FirestorePushTokenRegistry(FirebaseFirestore.instance);

  @lazySingleton
  PushCoordinator pushCoordinator(
    SessionCubit session,
    PushService push,
    PushTokenRegistry tokens,
    GoRouter router,
  ) => PushCoordinator(
    session: session,
    push: push,
    tokens: tokens,
    navigate: router.go,
  );

  /// Exchange rates over HTTP: in dev the client also gets the chaos
  /// interceptor that the debug panel controls.
  @dev
  @lazySingleton
  FxRatesRepository devFxRatesRepository(
    ChaosController chaos,
    KeyValueStore store,
  ) => ExchangeRateApiRepository(
    dio: createDioClient(
      baseUrl: ExchangeRateApiRepository.baseUrl,
      chaos: chaos,
    ),
    store: store,
  );

  @prod
  @lazySingleton
  FxRatesRepository prodFxRatesRepository(KeyValueStore store) =>
      ExchangeRateApiRepository(
        dio: createDioClient(baseUrl: ExchangeRateApiRepository.baseUrl),
        store: store,
      );

  /// The dev router adds the debug panel; prod has no route to it.
  @dev
  @lazySingleton
  GoRouter devRouter(
    SessionCubit session,
    PersonalizationCubit personalization,
    OnboardingRepository onboardingRepository,
    AuthRepository authRepository,
    AccountsRepository accountsRepository,
    FxRatesRepository fxRatesRepository,
    DebugTools debugTools,
  ) => createRouter(
    session: session,
    personalization: personalization,
    onboardingRepository: onboardingRepository,
    authRepository: authRepository,
    accountsRepository: accountsRepository,
    fxRatesRepository: fxRatesRepository,
    debugTools: debugTools,
  );

  @prod
  @lazySingleton
  GoRouter prodRouter(
    SessionCubit session,
    PersonalizationCubit personalization,
    OnboardingRepository onboardingRepository,
    AuthRepository authRepository,
    AccountsRepository accountsRepository,
    FxRatesRepository fxRatesRepository,
  ) => createRouter(
    session: session,
    personalization: personalization,
    onboardingRepository: onboardingRepository,
    authRepository: authRepository,
    accountsRepository: accountsRepository,
    fxRatesRepository: fxRatesRepository,
  );

  /// Debug tooling: registered only in the dev environment (dev flavor).
  @dev
  @lazySingleton
  ChaosController get chaosController => ChaosController();

  @dev
  @lazySingleton
  FirestoreNetworkSwitch get firestoreNetworkSwitch => FirestoreNetworkSwitch(
    ({required enabled}) => enabled
        ? FirebaseFirestore.instance.enableNetwork()
        : FirebaseFirestore.instance.disableNetwork(),
  );

  @dev
  @lazySingleton
  DebugTools debugTools(
    ChaosController chaos,
    FirestoreNetworkSwitch firestoreNetwork,
    PushService push,
  ) => DebugTools(chaos: chaos, firestoreNetwork: firestoreNetwork, push: push);
}
