import 'package:accounts/accounts.dart';
import 'package:auth/auth.dart';
import 'package:banking_app/app/config/app_config.dart';
import 'package:banking_app/app/personalization/personalization_cubit.dart';
import 'package:banking_app/app/personalization/personalization_source.dart';
import 'package:banking_app/app/router/app_router.dart';
import 'package:banking_app/app/session_effects.dart';
import 'package:core/core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

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
  GoRouter router(
    SessionCubit session,
    PersonalizationCubit personalization,
    OnboardingRepository onboardingRepository,
    AuthRepository authRepository,
    AccountsRepository accountsRepository,
  ) => createRouter(
    session: session,
    personalization: personalization,
    onboardingRepository: onboardingRepository,
    authRepository: authRepository,
    accountsRepository: accountsRepository,
  );

  /// Debug tooling: registered only in the dev environment (dev flavor).
  @dev
  @lazySingleton
  ChaosController get chaosController => ChaosController();
}
