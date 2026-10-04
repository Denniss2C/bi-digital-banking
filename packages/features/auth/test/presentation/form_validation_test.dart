import 'package:auth/src/presentation/forms/form_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emails need a user, a domain and a dot', () {
    expect(validateEmail('mateo@nexo.ec'), isNull);
    expect(validateEmail('  mateo@nexo.ec '), isNull);
    expect(validateEmail('mateo@nexo'), FieldError.invalidEmail);
    expect(validateEmail('mateo.nexo.ec'), FieldError.invalidEmail);
    expect(validateEmail(''), FieldError.invalidEmail);
  });

  test('names need at least two characters', () {
    expect(validateName('Mateo'), isNull);
    expect(validateName(' M '), FieldError.nameRequired);
  });

  test('sign in only requires a non-empty password', () {
    expect(validateExistingPassword('x'), isNull);
    expect(validateExistingPassword(''), FieldError.passwordRequired);
  });

  test('new passwords need 8+ characters with letters and numbers', () {
    expect(validateNewPassword('nexo2026'), isNull);
    expect(validateNewPassword('nexo26'), FieldError.weakPassword);
    expect(validateNewPassword('nexonexo'), FieldError.weakPassword);
    expect(validateNewPassword('20262026'), FieldError.weakPassword);
  });
}
