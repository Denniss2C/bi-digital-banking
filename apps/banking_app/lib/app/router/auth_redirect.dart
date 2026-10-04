import 'package:auth/auth.dart';
import 'package:banking_app/app/router/app_routes.dart';

/// Routes a signed-out user may visit.
const _publicRoutes = {AppRoutes.onboarding, AppRoutes.login};

/// Where the router must send the user, or `null` to stay on [location].
///
/// - Session not known yet (startup): wait on the splash.
/// - Signed out: onboarding the first time, then the login.
/// - Signed in: never stay on splash, onboarding or login.
String? authRedirect({
  required SessionState session,
  required bool hasSeenOnboarding,
  required String location,
}) {
  switch (session) {
    case SessionUnknown():
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SessionUnauthenticated():
      if (_publicRoutes.contains(location)) return null;
      return hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding;
    case SessionAuthenticated():
      final isEntryRoute =
          location == AppRoutes.splash || _publicRoutes.contains(location);
      return isEntryRoute ? AppRoutes.home : null;
  }
}
