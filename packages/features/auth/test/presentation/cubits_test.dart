import 'dart:async';

import 'package:auth/auth.dart';
import 'package:auth/src/presentation/forms/form_validation.dart';
import 'package:auth/src/presentation/sign_in/sign_in_cubit.dart';
import 'package:auth/src/presentation/sign_up/sign_up_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  group('SessionCubit', () {
    late StreamController<AppUser?> users;

    setUp(() {
      users = StreamController<AppUser?>();
      when(() => repository.userChanges()).thenAnswer((_) => users.stream);
    });

    tearDown(() => users.close());

    blocTest<SessionCubit, SessionState>(
      'follows the user stream: signed in, then signed out',
      build: () => SessionCubit(repository),
      act: (_) async {
        users.add(testUser);
        await Future<void>.delayed(Duration.zero);
        users.add(null);
      },
      expect: () => [
        const SessionAuthenticated(testUser),
        const SessionUnauthenticated(),
      ],
    );

    test('starts as unknown until Firebase reports the session', () {
      expect(SessionCubit(repository).state, const SessionUnknown());
    });

    test('signOut delegates to the repository', () async {
      when(
        () => repository.signOut(),
      ).thenAnswer((_) async => const Right(unit));

      await SessionCubit(repository).signOut();

      verify(() => repository.signOut()).called(1);
    });
  });

  group('SignInCubit', () {
    blocTest<SignInCubit, SignInState>(
      'an invalid form shows errors and does not call the server',
      build: () => SignInCubit(repository),
      act: (cubit) => cubit.submit(),
      expect: () => [const SignInState(showErrors: true)],
      verify: (_) => verifyNever(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ),
    );

    blocTest<SignInCubit, SignInState>(
      'valid credentials: submitting, then success',
      setUp: () => when(
        () => repository.signIn(email: 'a@b.ec', password: 'secret'),
      ).thenAnswer((_) async => const Right(testUser)),
      build: () => SignInCubit(repository),
      seed: () => const SignInState(email: 'a@b.ec', password: 'secret'),
      act: (cubit) => cubit.submit(),
      expect: () => [
        const SignInState(
          email: 'a@b.ec',
          password: 'secret',
          status: FormStatus.submitting,
          showErrors: true,
        ),
        const SignInState(
          email: 'a@b.ec',
          password: 'secret',
          status: FormStatus.success,
          showErrors: true,
        ),
      ],
    );

    blocTest<SignInCubit, SignInState>(
      'a rejected sign in keeps the failure until the user edits the form',
      setUp: () =>
          when(
            () => repository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async =>
                const Left(AuthFailure(code: AuthErrorCode.invalidCredentials)),
          ),
      build: () => SignInCubit(repository),
      seed: () => const SignInState(email: 'a@b.ec', password: 'wrong'),
      act: (cubit) async {
        await cubit.submit();
        cubit.passwordChanged('wrong2');
      },
      skip: 1,
      expect: () => [
        const SignInState(
          email: 'a@b.ec',
          password: 'wrong',
          status: FormStatus.failure,
          showErrors: true,
          failure: AuthFailure(code: AuthErrorCode.invalidCredentials),
        ),
        const SignInState(
          email: 'a@b.ec',
          password: 'wrong2',
          showErrors: true,
        ),
      ],
    );

    blocTest<SignInCubit, SignInState>(
      'password reset reports the email that received the link',
      setUp: () => when(
        () => repository.sendPasswordReset(email: 'a@b.ec'),
      ).thenAnswer((_) async => const Right(unit)),
      build: () => SignInCubit(repository),
      seed: () => const SignInState(email: 'a@b.ec'),
      act: (cubit) => cubit.sendPasswordReset(),
      expect: () => [
        const SignInState(email: 'a@b.ec', resetEmailSentTo: 'a@b.ec'),
      ],
    );

    blocTest<SignInCubit, SignInState>(
      'password reset with an invalid email only shows the error',
      build: () => SignInCubit(repository),
      seed: () => const SignInState(email: 'nope'),
      act: (cubit) => cubit.sendPasswordReset(),
      expect: () => [const SignInState(email: 'nope', showErrors: true)],
    );
  });

  group('SignUpCubit', () {
    blocTest<SignUpCubit, SignUpState>(
      'a weak password blocks the request',
      build: () => SignUpCubit(repository),
      seed: () =>
          const SignUpState(name: 'Mateo', email: 'a@b.ec', password: 'short'),
      act: (cubit) => cubit.submit(),
      expect: () => [
        const SignUpState(
          name: 'Mateo',
          email: 'a@b.ec',
          password: 'short',
          showErrors: true,
        ),
      ],
      verify: (_) => verifyNever(
        () => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ),
    );

    blocTest<SignUpCubit, SignUpState>(
      'an existing email ends in a failure',
      setUp: () =>
          when(
            () => repository.signUp(
              name: 'Mateo',
              email: 'a@b.ec',
              password: 'nexo2026',
            ),
          ).thenAnswer(
            (_) async =>
                const Left(AuthFailure(code: AuthErrorCode.emailAlreadyInUse)),
          ),
      build: () => SignUpCubit(repository),
      seed: () => const SignUpState(
        name: 'Mateo',
        email: 'a@b.ec',
        password: 'nexo2026',
      ),
      act: (cubit) => cubit.submit(),
      skip: 1,
      expect: () => [
        const SignUpState(
          name: 'Mateo',
          email: 'a@b.ec',
          password: 'nexo2026',
          status: FormStatus.failure,
          showErrors: true,
          failure: AuthFailure(code: AuthErrorCode.emailAlreadyInUse),
        ),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'valid data creates the account',
      setUp: () => when(
        () => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(testUser)),
      build: () => SignUpCubit(repository),
      seed: () => const SignUpState(
        name: 'Mateo',
        email: 'a@b.ec',
        password: 'nexo2026',
      ),
      act: (cubit) => cubit.submit(),
      skip: 1,
      expect: () => [
        const SignUpState(
          name: 'Mateo',
          email: 'a@b.ec',
          password: 'nexo2026',
          status: FormStatus.success,
          showErrors: true,
        ),
      ],
    );
  });
}
