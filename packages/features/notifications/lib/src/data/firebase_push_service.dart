import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notifications/src/domain/push.dart';

/// Reads a Firebase message: `notification` gives the title and body and
/// `data.route` the screen to open.
PushMessage pushMessageFrom(RemoteMessage message) => PushMessage(
  title: message.notification?.title,
  body: message.notification?.body,
  route: switch (message.data['route']) {
    final String route when route.isNotEmpty => route,
    _ => null,
  },
);

/// [PushService] on Firebase Cloud Messaging.
class FirebasePushService implements PushService {
  /// The message streams are static in the plugin; they can be replaced in
  /// tests.
  FirebasePushService(
    this.messaging, {
    Stream<RemoteMessage>? onMessage,
    Stream<RemoteMessage>? onMessageOpenedApp,
  }) : _onMessage = onMessage ?? FirebaseMessaging.onMessage,
       _onMessageOpenedApp =
           onMessageOpenedApp ?? FirebaseMessaging.onMessageOpenedApp;

  final FirebaseMessaging messaging;
  final Stream<RemoteMessage> _onMessage;
  final Stream<RemoteMessage> _onMessageOpenedApp;

  @override
  Future<PushPermission> requestPermission() async {
    final settings = await messaging.requestPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermission.granted,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => PushPermission.denied,
      AuthorizationStatus.notDetermined => PushPermission.notDetermined,
    };
  }

  @override
  Future<String?> token() => messaging.getToken();

  @override
  Stream<String> get tokenRefreshes => messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get foregroundMessages => _onMessage.map(pushMessageFrom);

  @override
  Stream<PushMessage> get openedMessages =>
      _onMessageOpenedApp.map(pushMessageFrom);

  @override
  Future<PushMessage?> initialMessage() async {
    final message = await messaging.getInitialMessage();
    return message == null ? null : pushMessageFrom(message);
  }
}
