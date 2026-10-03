import 'package:auth/src/domain/entities/app_user.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Authentication contract used by the presentation layer.
///
/// Operations return `Either<Failure, T>`: an `AuthFailure` with an
/// `AuthErrorCode` for business errors, or a `NetworkFailure` when offline.
abstract interface class AuthRepository {
  /// Emits the current user on sign-in, sign-out and profile changes
  /// (`null` when signed out). The session survives app restarts.
  Stream<AppUser?> userChanges();

  AppUser? get currentUser;

  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> sendPasswordReset({required String email});

  Future<Either<Failure, Unit>> signOut();
}
