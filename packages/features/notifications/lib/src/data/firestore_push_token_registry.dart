import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/src/domain/push.dart';

/// [PushTokenRegistry] in `users/{uid}.fcmTokens` (one user can have several
/// devices). The security rules let each user write only their own document.
class FirestorePushTokenRegistry implements PushTokenRegistry {
  FirestorePushTokenRegistry(this.firestore);

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      firestore.collection('users').doc(userId);

  @override
  Future<Either<Failure, Unit>> save({
    required String userId,
    required String token,
  }) => _guard(
    () => _user(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true)),
  );

  @override
  Future<Either<Failure, Unit>> remove({
    required String userId,
    required String token,
  }) => _guard(
    () => _user(userId).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true)),
  );

  Future<Either<Failure, Unit>> _guard(Future<void> Function() write) async {
    try {
      await write();
      return const Right(unit);
    } on FirebaseException catch (error) {
      return Left(switch (error.code) {
        'unavailable' || 'deadline-exceeded' => NetworkFailure(error.code),
        'permission-denied' ||
        'unauthenticated' => AuthFailure(message: error.code),
        _ => ServerFailure(message: error.code),
      });
    }
  }
}
