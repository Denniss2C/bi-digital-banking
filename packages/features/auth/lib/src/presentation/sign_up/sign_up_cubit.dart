import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/presentation/forms/form_validation.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SignUpState extends Equatable {
  const SignUpState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.status = FormStatus.idle,
    this.showErrors = false,
    this.failure,
  });

  final String name;
  final String email;
  final String password;
  final FormStatus status;

  /// Field errors are shown only after the first submit attempt.
  final bool showErrors;
  final Failure? failure;

  FieldError? get nameError => validateName(name);
  FieldError? get emailError => validateEmail(email);
  FieldError? get passwordError => validateNewPassword(password);
  bool get isValid =>
      nameError == null && emailError == null && passwordError == null;
  bool get isSubmitting => status == FormStatus.submitting;

  SignUpState copyWith({
    String? name,
    String? email,
    String? password,
    FormStatus? status,
    bool? showErrors,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return SignUpState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      showErrors: showErrors ?? this.showErrors,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    status,
    showErrors,
    failure,
  ];
}

/// Sign-up form. On success the session changes and the router navigates.
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._repository) : super(const SignUpState());

  final AuthRepository _repository;

  void nameChanged(String name) => emit(_edited(state.copyWith(name: name)));

  void emailChanged(String email) =>
      emit(_edited(state.copyWith(email: email)));

  void passwordChanged(String password) =>
      emit(_edited(state.copyWith(password: password)));

  Future<void> submit() async {
    if (state.isSubmitting) return;
    if (!state.isValid) return emit(state.copyWith(showErrors: true));

    emit(
      state.copyWith(
        status: FormStatus.submitting,
        showErrors: true,
        clearFailure: true,
      ),
    );
    final result = await _repository.signUp(
      name: state.name,
      email: state.email,
      password: state.password,
    );
    emit(
      result.match(
        (failure) =>
            state.copyWith(status: FormStatus.failure, failure: failure),
        (_) => state.copyWith(status: FormStatus.success),
      ),
    );
  }

  static SignUpState _edited(SignUpState state) =>
      state.copyWith(status: FormStatus.idle, clearFailure: true);
}
