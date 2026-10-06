import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

// Bloc states carry failures, and a bloc skips a state equal to the current
// one: equality decides whether a new error reaches the screen.
void main() {
  // Built at runtime: two `const` failures with the same data are a single
  // object, so `==` would return early without comparing them.
  List<Failure> failures(String message) => [
    NetworkFailure(message),
    ServerFailure(statusCode: 503, message: message),
    CacheFailure(message),
    AuthFailure(code: AuthErrorCode.weakPassword, message: message),
    ValidationFailure(code: 'insufficientFunds', message: message),
  ];

  test('failures with the same type and data are equal', () {
    expect(failures('boom'), failures('boom'));
  });

  test('the message is part of equality', () {
    final timeout = failures('timeout');
    final dns = failures('dns');
    for (var i = 0; i < timeout.length; i++) {
      expect(timeout[i], isNot(dns[i]));
    }
  });

  test('so is the data that tells two failures of a type apart', () {
    expect(
      const ServerFailure(statusCode: 500),
      isNot(const ServerFailure(statusCode: 503)),
    );
    expect(
      const AuthFailure(code: AuthErrorCode.invalidEmail),
      isNot(const AuthFailure(code: AuthErrorCode.weakPassword)),
    );
    expect(
      const ValidationFailure(code: 'limitExceeded'),
      isNot(const ValidationFailure(code: 'insufficientFunds')),
    );
  });

  test('different types never match, even with the same message', () {
    expect(const NetworkFailure('x'), isNot(const CacheFailure('x')));
  });
}
