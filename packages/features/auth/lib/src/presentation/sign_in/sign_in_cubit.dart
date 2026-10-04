import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/presentation/forms/form_validation.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SignInState extends Equatable {
  const SignInState({
    this.email = '',
    this.password = '',
    this.status = FormStatus.idle,
    this.showErrors = false,
    this.failure,
    this.resetEmailSentTo,
  });

  final String email;
  final String password;
  final FormStatus status;

  /// Field errors are shown only after the first submit attempt.
  final bool showErrors;
  final Failure? failure;

  /// Email that received a password reset link, if any.
  final String? resetEmailSentTo;

  FieldError? get emailError => validateEmail(email);
  FieldError? get passwordError => validateExistingPassword(password);
  bool get isValid => emailError == null && passwordError == null;
  bool get isSubmitting => status == FormStatus.submitting;

  SignInState copyWith({
    String? email,
    String? password,
    FormStatus? status,
    bool? showErrors,
    Failure? failure,
    bool clearFailure = false,
    String? resetEmailSentTo,
    bool clearResetEmail = false,
  }) {
    return SignInState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      showErrors: showErrors ?? this.showErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      resetEmailSentTo: clearResetEmail
          ? null
          : resetEmailSentTo ?? this.resetEmailSentTo,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    status,
    showErrors,
    failure,
    resetEmailSentTo,
  ];
}

/// Sign-in form. On success the session changes and the router navigates.
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._repository) : super(const SignInState());

  final AuthRepository _repository;

  void emailChanged(String email) => emit(
    state.copyWith(
      email: email,
      status: FormStatus.idle,
      clearFailure: true,
      clearResetEmail: true,
    ),
  );

  void passwordChanged(String password) => emit(
    state.copyWith(
      password: password,
      status: FormStatus.idle,
      clearFailure: true,
    ),
  );

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (!state.isValid) return emit(state.copyWith(showErrors: true));

    emit(
      state.copyWith(
        status: FormStatus.submitting,
        showErrors: true,
        clearFailure: true,
        clearResetEmail: true,
      ),
    );
    final result = await _repository.signIn(
      email: state.email,
      password: state.password,
    );
    // The screen may close while waiting (e.g. the redirect after sign-in).
    if (isClosed) return;
    emit(
      result.match(
        (failure) =>
            state.copyWith(status: FormStatus.failure, failure: failure),
        (_) => state.copyWith(status: FormStatus.success),
      ),
    );
  }

  /// Sends a reset link to the email typed in the form.
  Future<void> sendPasswordReset() async {
    if (state.emailError != null) {
      return emit(state.copyWith(showErrors: true));
    }
    final result = await _repository.sendPasswordReset(email: state.email);
    if (isClosed) return;
    emit(
      result.match(
        (failure) =>
            state.copyWith(status: FormStatus.failure, failure: failure),
        (_) => state.copyWith(
          resetEmailSentTo: state.email.trim(),
          clearFailure: true,
        ),
      ),
    );
  }
}
