import 'package:auth/auth.dart';
import 'package:banking_app/app/router/app_routes.dart';
import 'package:banking_app/app/router/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  String? redirect(
    SessionState session,
    String location, {
    bool seen = false,
  }) => authRedirect(
    session: session,
    hasSeenOnboarding: seen,
    location: location,
  );

  group('authRedirect', () {
    test('waits on the splash while the session is unknown', () {
      const unknown = SessionUnknown();

      expect(redirect(unknown, AppRoutes.splash), isNull);
      expect(redirect(unknown, AppRoutes.home), AppRoutes.splash);
    });

    test('a signed-out first-time user goes to the onboarding', () {
      const out = SessionUnauthenticated();

      expect(redirect(out, AppRoutes.splash), AppRoutes.onboarding);
      expect(redirect(out, AppRoutes.home), AppRoutes.onboarding);
    });

    test('a signed-out returning user goes to the login', () {
      const out = SessionUnauthenticated();

      expect(redirect(out, AppRoutes.splash, seen: true), AppRoutes.login);
      expect(redirect(out, AppRoutes.accounts, seen: true), AppRoutes.login);
    });

    test('signed-out users may stay on the public routes', () {
      const out = SessionUnauthenticated();

      expect(redirect(out, AppRoutes.login), isNull);
      expect(redirect(out, AppRoutes.onboarding, seen: true), isNull);
    });

    test('a signed-in user never stays on the entry routes', () {
      const signedIn = SessionAuthenticated(testUser);

      for (final entry in [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
      ]) {
        expect(redirect(signedIn, entry), AppRoutes.home);
      }
      expect(redirect(signedIn, AppRoutes.accounts), isNull);
    });
  });
}
