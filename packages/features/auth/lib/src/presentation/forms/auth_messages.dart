import 'package:auth/l10n/gen/auth_localizations.dart';
import 'package:auth/src/presentation/forms/form_validation.dart';
import 'package:core/core.dart';

/// Localized text of a validation error.
String fieldErrorMessage(AuthLocalizations l10n, FieldError error) {
  return switch (error) {
    FieldError.nameRequired => l10n.errorNameRequired,
    FieldError.invalidEmail => l10n.errorEmailInvalid,
    FieldError.passwordRequired => l10n.errorPasswordRequired,
    FieldError.weakPassword => l10n.errorPasswordWeak,
  };
}

/// Localized text of a failed auth operation.
String failureMessage(AuthLocalizations l10n, Failure failure) {
  return switch (failure) {
    NetworkFailure() => l10n.errorNetwork,
    AuthFailure(:final code) => switch (code) {
      AuthErrorCode.invalidCredentials => l10n.errorInvalidCredentials,
      AuthErrorCode.invalidEmail => l10n.errorEmailInvalid,
      AuthErrorCode.userDisabled => l10n.errorUserDisabled,
      AuthErrorCode.emailAlreadyInUse => l10n.errorEmailInUse,
      AuthErrorCode.weakPassword => l10n.errorWeakPassword,
      AuthErrorCode.tooManyRequests => l10n.errorTooManyRequests,
      AuthErrorCode.unknown => l10n.errorUnknown,
    },
    ServerFailure() || CacheFailure() => l10n.errorUnknown,
  };
}
