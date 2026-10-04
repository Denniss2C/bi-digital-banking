import 'dart:async';

import 'package:auth/auth.dart';
import 'package:auth/src/presentation/sign_in/sign_in_cubit.dart';
import 'package:auth/src/presentation/sign_up/sign_up_cubit.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

/// The screen can close while a request is in flight (e.g. the redirect
/// after a successful sign-in): the answer must not reach a closed cubit.
void main() {
  late MockAuthRepository repository;
  const user = AppUser(id: 'u', email: 'mateo@nexo.ec');

  setUp(() => repository = MockAuthRepository());

  test('sign in', () async {
    final response = Completer<Either<Failure, AppUser>>();
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => response.future);
    final cubit = SignInCubit(repository)
      ..emailChanged('mateo@nexo.ec')
      ..passwordChanged('nexo2026');

    final submitting = cubit.submit();
    await cubit.close();
    response.complete(const Right(user));

    await expectLater(submitting, completes);
  });

  test('password reset', () async {
    final response = Completer<Either<Failure, Unit>>();
    when(
      () => repository.sendPasswordReset(email: any(named: 'email')),
    ).thenAnswer((_) => response.future);
    final cubit = SignInCubit(repository)..emailChanged('mateo@nexo.ec');

    final sending = cubit.sendPasswordReset();
    await cubit.close();
    response.complete(const Right(unit));

    await expectLater(sending, completes);
  });

  test('sign up', () async {
    final response = Completer<Either<Failure, AppUser>>();
    when(
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => response.future);
    final cubit = SignUpCubit(repository)
      ..nameChanged('Mateo')
      ..emailChanged('mateo@nexo.ec')
      ..passwordChanged('nexo2026');

    final submitting = cubit.submit();
    await cubit.close();
    response.complete(const Right(user));

    await expectLater(submitting, completes);
  });
}
