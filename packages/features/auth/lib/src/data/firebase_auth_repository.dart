import 'package:auth/src/data/firebase_auth_failure_mapper.dart';
import 'package:auth/src/domain/entities/app_user.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

/// [AuthRepository] backed by Firebase Auth (email and password).
///
/// Firebase persists the session on the device, so a signed-in user stays
/// signed in after restarting the app.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_toAppUserOrNull);

  @override
  AppUser? get currentUser => _toAppUserOrNull(_auth.currentUser);

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toAppUser(credential.user!);
    });
  }

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      // `user` still holds the old profile; return the name just saved.
      return AppUser(
        id: user.uid,
        email: user.email!,
        displayName: name.trim(),
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordReset({required String email}) {
    return _guard(() async {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> signOut() {
    return _guard(() async {
      await _auth.signOut();
      return unit;
    });
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on FirebaseAuthException catch (exception) {
      return Left(mapFirebaseAuthException(exception));
    }
  }

  static AppUser? _toAppUserOrNull(User? user) =>
      user == null ? null : _toAppUser(user);

  static AppUser _toAppUser(User user) => AppUser(
    id: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
  );
}
