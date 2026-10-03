import 'package:auth/src/data/firebase_auth_failure_mapper.dart';
import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedCodes = {
    'invalid-credential': AuthErrorCode.invalidCredentials,
    'wrong-password': AuthErrorCode.invalidCredentials,
    'user-not-found': AuthErrorCode.invalidCredentials,
    'invalid-email': AuthErrorCode.invalidEmail,
    'user-disabled': AuthErrorCode.userDisabled,
    'email-already-in-use': AuthErrorCode.emailAlreadyInUse,
    'weak-password': AuthErrorCode.weakPassword,
    'too-many-requests': AuthErrorCode.tooManyRequests,
    'something-new': AuthErrorCode.unknown,
  };

  group('mapFirebaseAuthException', () {
    for (final MapEntry(key: firebaseCode, value: code)
        in expectedCodes.entries) {
      test('$firebaseCode -> $code', () {
        final failure = mapFirebaseAuthException(
          FirebaseAuthException(code: firebaseCode),
        );

        expect(failure, AuthFailure(code: code, message: firebaseCode));
      });
    }

    test('network-request-failed -> NetworkFailure', () {
      expect(
        mapFirebaseAuthException(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        isA<NetworkFailure>(),
      );
    });
  });
}
