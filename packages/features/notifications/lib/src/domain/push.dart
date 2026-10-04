import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

/// A push notification as the app uses it.
final class PushMessage extends Equatable {
  const PushMessage({this.title, this.body, this.route});

  final String? title;
  final String? body;

  /// In-app location to open on tap (`data.route` of the message), e.g.
  /// `/fx`. The shell checks it is a screen of the app before opening it.
  final String? route;

  @override
  List<Object?> get props => [title, body, route];
}

enum PushPermission { granted, denied, notDetermined }

/// Push notifications of this device.
abstract interface class PushService {
  /// Asks the user (Android 13+ and iOS show a system dialog once).
  Future<PushPermission> requestPermission();

  /// This device's token, or `null` if there is none yet.
  Future<String?> token();

  /// New tokens issued by the provider while the app runs.
  Stream<String> get tokenRefreshes;

  /// Messages that arrive while the app is open (the system shows nothing).
  Stream<PushMessage> get foregroundMessages;

  /// Notifications tapped while the app was in the background.
  Stream<PushMessage> get openedMessages;

  /// The notification that launched the app from closed, if any.
  Future<PushMessage?> initialMessage();
}

/// Where each user's device tokens are kept, so a backend can target them.
abstract interface class PushTokenRegistry {
  Future<Either<Failure, Unit>> save({
    required String userId,
    required String token,
  });

  Future<Either<Failure, Unit>> remove({
    required String userId,
    required String token,
  });
}
