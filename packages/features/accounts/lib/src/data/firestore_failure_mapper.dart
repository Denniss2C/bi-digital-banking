import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

/// Maps Firestore errors (and malformed documents) to typed failures.
Failure mapFirestoreError(Object error) {
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
