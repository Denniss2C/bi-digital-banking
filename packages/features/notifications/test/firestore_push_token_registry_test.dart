import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:notifications/notifications.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestorePushTokenRegistry registry;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    registry = FirestorePushTokenRegistry(firestore);
  });

  Future<Map<String, dynamic>?> profile() async =>
      (await firestore.doc('users/u').get()).data();

  test('saves each device token once, keeping the profile', () async {
    await firestore.doc('users/u').set({'name': 'Mateo'});

    await registry.save(userId: 'u', token: 'phone');
    await registry.save(userId: 'u', token: 'phone');
    final result = await registry.save(userId: 'u', token: 'tablet');

    expect(result.isRight(), isTrue);
    expect((await profile())?['fcmTokens'], ['phone', 'tablet']);
    expect((await profile())?['name'], 'Mateo');
  });

  test('removes only the given token', () async {
    await registry.save(userId: 'u', token: 'phone');
    await registry.save(userId: 'u', token: 'tablet');

    await registry.remove(userId: 'u', token: 'phone');

    expect((await profile())?['fcmTokens'], ['tablet']);
  });

  group('a failed write becomes a typed failure', () {
    const failures = <String, Failure>{
      'unavailable': NetworkFailure('unavailable'),
      'deadline-exceeded': NetworkFailure('deadline-exceeded'),
      'permission-denied': AuthFailure(message: 'permission-denied'),
      'unauthenticated': AuthFailure(message: 'unauthenticated'),
      'internal': ServerFailure(message: 'internal'),
    };

    for (final MapEntry(key: code, value: failure) in failures.entries) {
      test(code, () async {
        whenCalling(Invocation.method(#set, null))
            .on(firestore.doc('users/u'))
            .thenThrow(
              FirebaseException(plugin: 'cloud_firestore', code: code),
            );

        expect(
          await registry.save(userId: 'u', token: 'phone'),
          Left<Failure, Unit>(failure),
        );
        expect(
          await registry.remove(userId: 'u', token: 'phone'),
          Left<Failure, Unit>(failure),
        );
      });
    }
  });
}
