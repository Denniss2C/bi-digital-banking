import 'package:accounts/src/domain/entities/transfer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

/// Thrown inside a Firestore transaction to abort it when a business rule
/// fails against fresh data (nothing is written).
class TransferRuleException implements Exception {
  const TransferRuleException(this.error);

  final TransferError error;
}

/// Maps Firestore errors (and malformed documents) to typed failures.
Failure mapFirestoreError(Object error) {
  if (error is TransferRuleException) {
    return ValidationFailure(code: error.error.name);
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => NetworkFailure(error.code),
      'permission-denied' ||
      'unauthenticated' => AuthFailure(message: error.code),
      _ => ServerFailure(message: error.code),
    };
  }
  if (error is FormatException) {
    return ServerFailure(message: 'Invalid document: ${error.message}');
  }
  return ServerFailure(message: '$error');
}
