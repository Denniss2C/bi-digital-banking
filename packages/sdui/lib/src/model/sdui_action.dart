import 'package:equatable/equatable.dart';

/// Something a component asks the host app to do, such as opening a screen.
///
/// The server only declares the intent; the shell decides how to run it and
/// may refuse it. Unknown or malformed actions parse to `null`, so a
/// component hides its button instead of showing one that does nothing.
sealed class SduiAction extends Equatable {
  const SduiAction();

  /// Reads an action object, e.g.
  /// `{"type": "navigate", "route": "/accounts/transfer"}`.
  static SduiAction? fromJson(Object? json) {
    return switch (json) {
      {'type': 'navigate', 'route': final String route}
          when _isInAppRoute(route) =>
        SduiNavigateAction(route),
      _ => null,
    };
  }

  // Only in-app locations: "/path", never "//host" or "https://...".
  static bool _isInAppRoute(String route) =>
      route.startsWith('/') && !route.startsWith('//');
}

/// Opens an in-app route (a go_router location).
final class SduiNavigateAction extends SduiAction {
  const SduiNavigateAction(this.route);

  final String route;

  @override
  List<Object?> get props => [route];
}
