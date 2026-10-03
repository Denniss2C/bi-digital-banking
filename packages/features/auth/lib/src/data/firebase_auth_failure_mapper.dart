import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth error codes to typed failures.
///
/// With email enumeration protection (Firebase default), a wrong password
/// and an unknown email both arrive as `invalid-credential`, so the UI never
/// reveals whether an account exists.
Failure mapFirebaseAuthException(FirebaseAuthException exception) {
  final code = switch (exception.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => AuthErrorCode.invalidCredentials,
    'invalid-email' => AuthErrorCode.invalidEmail,
    'user-disabled' => AuthErrorCode.userDisabled,
    'email-already-in-use' => AuthErrorCode.emailAlreadyInUse,
    'weak-password' => AuthErrorCode.weakPassword,
    'too-many-requests' => AuthErrorCode.tooManyRequests,
    'network-request-failed' => null,
    _ => AuthErrorCode.unknown,
  };
  if (code == null) return NetworkFailure(exception.code);
  return AuthFailure(code: code, message: exception.code);
}
