import 'package:auth/auth.dart';
import 'package:banking_app/app/router/app_router.dart';
import 'package:core/core.dart';
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
  GoRouter router(
    SessionCubit session,
    OnboardingRepository onboardingRepository,
    AuthRepository authRepository,
  ) => createRouter(
    session: session,
    onboardingRepository: onboardingRepository,
    authRepository: authRepository,
  );

  /// Debug tooling: registered only in the dev environment (dev flavor).
  @dev
  @lazySingleton
  ChaosController get chaosController => ChaosController();
}
