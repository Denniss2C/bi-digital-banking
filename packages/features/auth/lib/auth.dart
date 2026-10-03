/// Auth feature: onboarding, sign up, sign in and session.
///
/// Depends only on `core`, `design_system` and `sdui`; the app shell composes
/// it (routes and dependencies).
library;

export 'src/data/firebase_auth_repository.dart';
export 'src/data/local_onboarding_repository.dart';
export 'src/domain/entities/app_user.dart';
export 'src/domain/repositories/auth_repository.dart';
export 'src/domain/repositories/onboarding_repository.dart';
