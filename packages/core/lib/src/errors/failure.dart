import 'package:equatable/equatable.dart';

/// Typed error returned by repositories inside `Either<Failure, T>`.
///
/// [message] is technical (for logs); the presentation layer maps each
/// subtype to a localized, user-facing text.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// No connectivity, DNS errors or timeouts.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network unavailable']);
}

/// The server answered with an error or an unexpected payload.
final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode, String message = 'Server error'})
    : super(message);

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// Local cache could not be read or written.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

/// Why an authentication operation failed. The UI maps each code to a
/// localized message.
enum AuthErrorCode {
  invalidCredentials,
  invalidEmail,
  userDisabled,
  emailAlreadyInUse,
  weakPassword,
  tooManyRequests,
  unknown,
}

/// Invalid credentials, expired session or missing permissions.
final class AuthFailure extends Failure {
  const AuthFailure({
    this.code = AuthErrorCode.unknown,
    String message = 'Authentication error',
  }) : super(message);

  final AuthErrorCode code;

  @override
  List<Object?> get props => [message, code];
}
