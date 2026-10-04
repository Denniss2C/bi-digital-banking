/// Lifecycle of a form submission.
enum FormStatus { idle, submitting, success, failure }

/// Validation errors of the auth forms. The UI maps them to localized text.
enum FieldError { nameRequired, invalidEmail, passwordRequired, weakPassword }

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _hasLetter = RegExp('[A-Za-z]');
final _hasDigit = RegExp(r'\d');

FieldError? validateName(String name) =>
    name.trim().length >= 2 ? null : FieldError.nameRequired;

FieldError? validateEmail(String email) =>
    _emailPattern.hasMatch(email.trim()) ? null : FieldError.invalidEmail;

/// Signing in only needs a non-empty password; the server decides the rest.
FieldError? validateExistingPassword(String password) =>
    password.isEmpty ? FieldError.passwordRequired : null;

/// New passwords: at least 8 characters with letters and numbers (Firebase
/// alone would accept 6 characters of any kind).
FieldError? validateNewPassword(String password) {
  final strong =
      password.length >= 8 &&
      _hasLetter.hasMatch(password) &&
      _hasDigit.hasMatch(password);
  return strong ? null : FieldError.weakPassword;
}
