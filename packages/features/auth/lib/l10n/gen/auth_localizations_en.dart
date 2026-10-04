// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AuthLocalizationsEn extends AuthLocalizations {
  AuthLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingHaveAccount => 'Already have an account?';

  @override
  String get onboardingSignIn => 'Sign in';

  @override
  String onboardingStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingBankingTab => 'Banking';

  @override
  String get onboardingBankingTitle => 'Your bank in your pocket';

  @override
  String get onboardingBankingBody =>
      'Manage your accounts, balances and transfers in Ecuador without visiting a branch. 100% digital.';

  @override
  String get onboardingSecurityTab => 'Security';

  @override
  String get onboardingSecurityTitle => 'Bank-grade security';

  @override
  String get onboardingSecurityBody =>
      'Your session is protected and your data is never shared with third parties.';

  @override
  String get onboardingSavingsTab => 'Savings';

  @override
  String get onboardingSavingsTitle => 'Grow your money';

  @override
  String get onboardingSavingsBody =>
      'Track your movements and check exchange rates in real time.';

  @override
  String get signInTab => 'Sign in';

  @override
  String get signUpTab => 'Create account';

  @override
  String get signInHeadline => 'Welcome back';

  @override
  String get signInSubtitle => 'Sign in to your digital bank';

  @override
  String get signUpHeadline => 'Open your digital account';

  @override
  String get signUpSubtitle => 'In a few minutes, no queues';

  @override
  String get nameLabel => 'Full name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRules => 'At least 8 characters, with letters and numbers';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get signInAction => 'Sign in';

  @override
  String get signUpAction => 'Create account';

  @override
  String get securityTipTitle => 'Security tip';

  @override
  String get securityTipBody =>
      'Never share your password or verification codes with anyone, not even Nexo.';

  @override
  String get noAccountQuestion => 'Don\'t have an account yet?';

  @override
  String get registerAction => 'Sign up';

  @override
  String get haveAccountQuestion => 'Already have an account?';

  @override
  String get errorNameRequired => 'Enter your name';

  @override
  String get errorEmailInvalid => 'Enter a valid email';

  @override
  String get errorPasswordRequired => 'Enter your password';

  @override
  String get errorPasswordWeak =>
      'Use at least 8 characters, with letters and numbers';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password';

  @override
  String get errorEmailInUse => 'An account with this email already exists';

  @override
  String get errorWeakPassword => 'The password is too weak';

  @override
  String get errorUserDisabled => 'This account is disabled';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String resetEmailSent(String email) {
    return 'We sent a password reset link to $email.';
  }
}
