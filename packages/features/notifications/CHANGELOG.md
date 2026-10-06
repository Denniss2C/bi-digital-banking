# Changelog de `notifications`

Este paquete no se publica por separado: la versión que se entrega es la de la app (ver
[ADR-001](../../../docs/adr/ADR-001-monorepo-modular.md)). El detalle de cada cambio está en el
[CHANGELOG del monorepo](../../../CHANGELOG.md); aquí queda qué trae el paquete en cada versión.

## [0.0.1] - 2026-10-05

Primera versión, incluida en la app 1.0.0.

### Added

- `PushService` sobre Firebase Cloud Messaging: permiso, token y sus renovaciones, mensajes con la app abierta, toques
  en notificaciones y el mensaje que abrió la app.
- `PushMessage`, con la ruta que abre (`data.route`).
- `PushTokenRegistry`: los tokens en `users/{uid}.fcmTokens`, uno por dispositivo, con errores de Firestore como
  `Failure` tipadas.
