import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;
  late _MockUserCredential credential;
  late FirebaseAuthRepository repository;

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    credential = _MockUserCredential();
    repository = FirebaseAuthRepository(firebaseAuth);

    when(() => user.uid).thenReturn('uid-1');
    when(() => user.email).thenReturn('mateo@nexo.ec');
    when(() => user.displayName).thenReturn('Mateo');
    when(() => credential.user).thenReturn(user);
  });

  group('signIn', () {
    test('returns the user and trims the email', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      final result = await repository.signIn(
        email: '  mateo@nexo.ec ',
        password: 'secret123',
      );

      expect(
        result,
        const Right<Failure, AppUser>(
          AppUser(id: 'uid-1', email: 'mateo@nexo.ec', displayName: 'Mateo'),
        ),
      );
      verify(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: 'mateo@nexo.ec',
          password: 'secret123',
        ),
      ).called(1);
    });

    test('maps wrong credentials to AuthFailure.invalidCredentials', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      final result = await repository.signIn(email: 'a@b.ec', password: 'x');

      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          AuthErrorCode.invalidCredentials,
        ),
      );
    });

    test('maps a network error to NetworkFailure', () async {
      when(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final result = await repository.signIn(email: 'a@b.ec', password: 'x');

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });

  group('signUp', () {
    test('creates the account and saves the display name', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);
      when(() => user.updateDisplayName(any())).thenAnswer((_) async {});

      final result = await repository.signUp(
        name: ' Mateo Moreno ',
        email: 'mateo@nexo.ec',
        password: 'secret123',
      );

      expect(
        result.getRight().toNullable(),
        const AppUser(
          id: 'uid-1',
          email: 'mateo@nexo.ec',
          displayName: 'Mateo Moreno',
        ),
      );
      verify(() => user.updateDisplayName('Mateo Moreno')).called(1);
    });

    test('maps an existing email to AuthFailure.emailAlreadyInUse', () async {
      when(
        () => firebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final result = await repository.signUp(
        name: 'Mateo',
        email: 'mateo@nexo.ec',
        password: 'secret123',
      );

      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          AuthErrorCode.emailAlreadyInUse,
        ),
      );
    });
  });

  test('sendPasswordReset trims the email and succeeds', () async {
    when(
      () => firebaseAuth.sendPasswordResetEmail(email: any(named: 'email')),
    ).thenAnswer((_) async {});

    final result = await repository.sendPasswordReset(email: ' a@b.ec ');

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => firebaseAuth.sendPasswordResetEmail(email: 'a@b.ec'),
    ).called(1);
  });

  test('signOut succeeds', () async {
    when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

    expect(await repository.signOut(), const Right<Failure, Unit>(unit));
  });

  test('userChanges maps Firebase users and sign-outs', () {
    when(
      () => firebaseAuth.userChanges(),
    ).thenAnswer((_) => Stream.fromIterable([user, null]));

    expect(
      repository.userChanges(),
      emitsInOrder([
        const AppUser(
          id: 'uid-1',
          email: 'mateo@nexo.ec',
          displayName: 'Mateo',
        ),
        null,
      ]),
    );
  });
}
