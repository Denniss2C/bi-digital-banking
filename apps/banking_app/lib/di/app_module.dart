import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/debug/debug_tools.dart';
import 'package:banking_app/app/observability/app_observability.dart';
import 'package:banking_app/app/observability/firebase_telemetry.dart';
import 'package:banking_app/app/observability/performance_http_interceptor.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/app/personalization/personalization_source.dart';
import 'package:banking_app/app/push/push_coordinator.dart';
import 'package:banking_app/app/router/app_router.dart';
import 'package:banking_app/app/session_effects.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
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
  Telemetry get telemetry => FirebaseTelemetry(
    analytics: FirebaseAnalytics.instance,
    crashlytics: FirebaseCrashlytics.instance,
    performance: FirebasePerformance.instance,
  );

  @lazySingleton
  AppObservability appObservability(
    Telemetry telemetry,
    SessionCubit session,
    GoRouter router,
  ) => AppObservability(telemetry: telemetry, session: session, router: router);

  @lazySingleton
  SessionEffects sessionEffects(
    SessionCubit session,
    AccountsRepository accounts,
    Telemetry telemetry,
  ) => SessionEffects(
    session: session,
    accounts: accounts,
    telemetry: telemetry,
  );

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
    Telemetry telemetry,
  ) => PushCoordinator(
    session: session,
    push: push,
    tokens: tokens,
    navigate: router.go,
    telemetry: telemetry,
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
      interceptors: [PerformanceHttpInterceptor(FirebasePerformance.instance)],
    ),
    store: store,
  );

  @prod
  @lazySingleton
  FxRatesRepository prodFxRatesRepository(KeyValueStore store) =>
      ExchangeRateApiRepository(
        dio: createDioClient(
          baseUrl: ExchangeRateApiRepository.baseUrl,
          interceptors: [
            PerformanceHttpInterceptor(FirebasePerformance.instance),
          ],
        ),
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
    Telemetry telemetry,
    DebugTools debugTools,
  ) => createRouter(
    session: session,
    personalization: personalization,
    onboardingRepository: onboardingRepository,
    authRepository: authRepository,
    accountsRepository: accountsRepository,
    fxRatesRepository: fxRatesRepository,
    telemetry: telemetry,
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
    Telemetry telemetry,
  ) => createRouter(
    session: session,
    personalization: personalization,
    onboardingRepository: onboardingRepository,
    authRepository: authRepository,
    accountsRepository: accountsRepository,
    fxRatesRepository: fxRatesRepository,
    telemetry: telemetry,
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
    Telemetry telemetry,
  ) => DebugTools(
    chaos: chaos,
    firestoreNetwork: firestoreNetwork,
    push: push,
    telemetry: telemetry,
    crash: FirebaseCrashlytics.instance.crash,
  );
}
