import 'package:auth/auth.dart';
import 'package:banking_app/app/push/push_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

import '../../helpers/fakes.dart';

/// Push service that fails like a device without Google Play services.
class _BrokenPushService extends FakePushService {
  @override
  Future<PushPermission> requestPermission() =>
      Future.error(Exception('no push on this device'));
}

void main() {
  late FakeAuthRepository auth;
  late SessionCubit session;
  late FakePushService push;
  late FakePushTokenRegistry tokens;
  late List<String> opened;
  late PushCoordinator coordinator;

  // Lets the session and the token requests complete.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> start({AppUser? signedIn, FakePushService? service}) async {
    auth = FakeAuthRepository(signedInUser: signedIn);
    session = SessionCubit(auth);
    push = service ?? FakePushService();
    tokens = FakePushTokenRegistry();
    opened = [];
    coordinator = PushCoordinator(
      session: session,
      push: push,
      tokens: tokens,
      navigate: opened.add,
    );
    await coordinator.start();
    await settle();
  }

  tearDown(() async {
    await coordinator.dispose();
    await session.close();
  });

  test('on sign-in it asks for permission and saves the token', () async {
    await start(signedIn: testUser);

    expect(push.permissionRequests, 1);
    expect(tokens.saved, [('uid-1', 'token-1')]);
    expect(coordinator.token.value, 'token-1');
  });

  test('a refreshed token is saved for the signed-in user', () async {
    await start(signedIn: testUser);

    push.refreshedTokens.add('token-2');
    await settle();

    expect(tokens.saved.last, ('uid-1', 'token-2'));
  });

  test('signing out removes the token of that user', () async {
    await start(signedIn: testUser);

    await auth.signOut();
    await settle();

    expect(tokens.removed, [('uid-1', 'token-1')]);
  });

  test('a tapped notification opens its screen', () async {
    await start(signedIn: testUser);

    push.opened.add(const PushMessage(title: 'Divisas', route: '/fx'));
    await settle();

    expect(opened, ['/fx']);
  });

  test('routes that are not screens of the app are ignored', () async {
    await start(signedIn: testUser);

    for (final route in ['/login', 'https://evil.example/fx', '/promo/x']) {
      push.opened.add(PushMessage(route: route));
    }
    push.opened.add(const PushMessage(title: 'Sin ruta'));
    await settle();

    expect(opened, isEmpty);
  });

  test('a tap while signed out opens its screen after the sign-in', () async {
    await start();

    push.opened.add(const PushMessage(route: '/fx'));
    await settle();
    expect(opened, isEmpty);

    await auth.signIn(email: 'mateo@nexo.ec', password: 'x');
    await settle();

    expect(opened, ['/fx']);
  });

  test('the notification that launched the app is opened', () async {
    await start(
      signedIn: testUser,
      service: FakePushService(
        launchMessage: const PushMessage(route: '/accounts'),
      ),
    );

    expect(opened, ['/accounts']);
  });

  test('messages in the foreground are passed on to the app', () async {
    await start(signedIn: testUser);
    final received = coordinator.foregroundMessages.first;

    push.foreground.add(const PushMessage(title: 'Hola'));

    expect(await received, const PushMessage(title: 'Hola'));
  });

  test('a device without push keeps working', () async {
    await start(signedIn: testUser, service: _BrokenPushService());

    expect(tokens.saved, isEmpty);
    expect(coordinator.token.value, isNull);
  });
}
