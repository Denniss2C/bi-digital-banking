# auth

Feature de autenticación de Nexo: onboarding, registro, inicio de sesión y sesión. Dueño: `@team-auth`.
Depende solo de `core` y `design_system`; el shell (`apps/banking_app`) lo compone.

## Capas

```text
lib/src/
  domain/   AppUser, AuthRepository, OnboardingRepository   (sin Flutter ni Firebase)
  data/     FirebaseAuthRepository, LocalOnboardingRepository, mapeo de errores de Firebase
  presentation/   SessionCubit, SignInCubit, SignUpCubit, AuthPage, OnboardingPage
lib/l10n/          AuthLocalizations (es/en): los textos del feature son de este equipo
```

- Las operaciones devuelven `Either<Failure, T>` (fpdart). Los errores de Firebase se traducen a
  `AuthFailure(code: AuthErrorCode.…)`, y `network-request-failed` pasa a `NetworkFailure`, así la UI muestra un
  mensaje preciso y traducido.
- Con la protección contra enumeración de emails de Firebase (activa por defecto), una contraseña incorrecta y un
  email inexistente llegan como `invalid-credential`: la app nunca revela si una cuenta existe.
- La sesión la persiste Firebase en el dispositivo. `userChanges()` emite en cada inicio y cierre de sesión y en cada
  cambio de perfil, como el nombre guardado al registrarse.
- El onboarding "visto" es una marca del **dispositivo** (en un `KeyValueStore` de `core`), porque se muestra antes
  de que haya un usuario.

## Presentación

- **`SessionCubit`**: refleja `userChanges()` (`SessionUnknown` → `SessionAuthenticated` / `SessionUnauthenticated`).
  El router del shell redirige con él; las pantallas nunca navegan al iniciar sesión.
- **`SignInCubit` / `SignUpCubit`**: validan en cliente (email, nombre, contraseña nueva de 8 o más caracteres con letras
  y números). Los errores aparecen recién después del primer intento. También manejan el envío del enlace para
  recuperar la contraseña.
- **Estados**: clases `sealed` + equatable con `copyWith` escrito a mano, sin freezed (ver el log de desvíos en
  `CLAUDE.md`).
- **Pantallas** según `docs/design/screens/`:
  - `OnboardingPage`: 3 pasos, y solo avisa la elección del usuario al shell;
  - `AuthPage`: login y registro, con su propia selección de modo.
- **Accesibilidad**: etiquetas en cada campo, autofill, toggle de contraseña con tooltip para lectores de pantalla,
  errores anunciados (`liveRegion`) y enlaces con color AA.

## Sin capa de casos de uso (decisión)

En este feature, cada caso de uso sería un pasamanos de una línea hacia el repositorio, así que los cubits usan el
repositorio directamente. Los casos de uso se agregan donde orquestan lógica de negocio; por ejemplo, una
transferencia valida saldo y mueve dinero entre cuentas en una transacción.

## Tests

```bash
cd packages/features/auth && flutter test
```

Firebase se mockea con mocktail: no hace falta un proyecto ni red.
