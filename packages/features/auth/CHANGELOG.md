# Changelog de `auth`

Este paquete no se publica por separado: la versión que se entrega es la de la app (ver
[ADR-001](../../../docs/adr/ADR-001-monorepo-modular.md)). El detalle de cada cambio está en el
[CHANGELOG del monorepo](../../../CHANGELOG.md); aquí queda qué trae el paquete en cada versión.

## [0.0.1] - 2026-10-05

Primera versión, incluida en la app 1.0.0.

### Added

- Onboarding de 3 pasos, que se marca como visto en el dispositivo.
- Registro, inicio de sesión y recuperación de contraseña con Firebase Auth (email y contraseña).
- `SessionCubit` con la sesión persistente, que el router del shell usa para redirigir.
- Errores de Firebase traducidos a mensajes precisos, sin revelar si una cuenta existe.
- Textos en español e inglés.
