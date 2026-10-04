import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications/notifications.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

class _MockSettings extends Mock implements NotificationSettings {}

RemoteMessage _message({String? title, Map<String, dynamic>? data}) =>
    RemoteMessage(
      notification: title == null
          ? null
          : RemoteNotification(title: title, body: 'Detalle'),
      data: data ?? const {},
    );

void main() {
  late _MockMessaging messaging;
  late StreamController<RemoteMessage> onMessage;
  late StreamController<RemoteMessage> onOpened;
  late FirebasePushService service;

  setUp(() {
    messaging = _MockMessaging();
    onMessage = StreamController.broadcast();
    onOpened = StreamController.broadcast();
    service = FirebasePushService(
      messaging,
      onMessage: onMessage.stream,
      onMessageOpenedApp: onOpened.stream,
    );
  });

  tearDown(() async {
    await onMessage.close();
    await onOpened.close();
  });

  test('reads title, body and route from a Firebase message', () {
    expect(
      pushMessageFrom(_message(title: 'Hola', data: {'route': '/fx'})),
      const PushMessage(title: 'Hola', body: 'Detalle', route: '/fx'),
    );
    expect(pushMessageFrom(_message(data: {'route': ''})), const PushMessage());
    expect(pushMessageFrom(_message(data: {'route': 3})), const PushMessage());
  });

  test('maps the permission answer', () async {
    for (final (status, expected) in [
      (AuthorizationStatus.authorized, PushPermission.granted),
      (AuthorizationStatus.provisional, PushPermission.granted),
      (AuthorizationStatus.denied, PushPermission.denied),
      (AuthorizationStatus.deniedPermanently, PushPermission.denied),
      (AuthorizationStatus.notDetermined, PushPermission.notDetermined),
    ]) {
      final settings = _MockSettings();
      when(() => settings.authorizationStatus).thenReturn(status);
      when(
        () => messaging.requestPermission(),
      ).thenAnswer((_) async => settings);

      expect(await service.requestPermission(), expected, reason: '$status');
    }
  });

  test('foreground and tapped messages arrive as PushMessage', () async {
    final foreground = service.foregroundMessages.first;
    final opened = service.openedMessages.first;

    onMessage.add(_message(title: 'Saldo'));
    onOpened.add(_message(title: 'Divisas', data: {'route': '/fx'}));

    expect(
      await foreground,
      const PushMessage(title: 'Saldo', body: 'Detalle'),
    );
    expect(
      await opened,
      const PushMessage(title: 'Divisas', body: 'Detalle', route: '/fx'),
    );
  });

  test('the message that launched the app, if any', () async {
    when(() => messaging.getInitialMessage()).thenAnswer((_) async => null);
    expect(await service.initialMessage(), isNull);

    when(() => messaging.getInitialMessage()).thenAnswer(
      (_) async => _message(title: 'Hola', data: {'route': '/accounts'}),
    );
    expect((await service.initialMessage())?.route, '/accounts');
  });

  test('token and refreshed tokens come from Firebase', () async {
    when(() => messaging.getToken()).thenAnswer((_) async => 'token-1');
    when(
      () => messaging.onTokenRefresh,
    ).thenAnswer((_) => Stream.value('token-2'));

    expect(await service.token(), 'token-1');
    expect(await service.tokenRefreshes.first, 'token-2');
  });
}
