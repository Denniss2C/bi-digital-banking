import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
