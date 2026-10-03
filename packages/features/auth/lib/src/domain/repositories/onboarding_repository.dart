/// Whether this device already showed the onboarding slides.
///
/// It is a device-level flag (stored locally), because onboarding happens
/// before there is a signed-in user.
abstract interface class OnboardingRepository {
  bool get hasSeenOnboarding;

  Future<void> markOnboardingSeen();
}
