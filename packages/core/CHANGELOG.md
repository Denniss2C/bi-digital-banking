# Changelog de `core`

Este paquete no se publica por separado: la versión que se entrega es la de la app (ver
[ADR-001](../../docs/adr/ADR-001-monorepo-modular.md)). El detalle de cada cambio está en el
[CHANGELOG del monorepo](../../CHANGELOG.md); aquí queda qué trae el paquete en cada versión.

## [0.0.1] - 2026-10-05

Primera versión, incluida en la app 1.0.0.

### Added

- Cliente HTTP `createDioClient` con `RetryInterceptor` (3 intentos, backoff exponencial con jitter, solo errores
  transitorios y métodos idempotentes) y `ChaosInterceptor` para el modo caos de dev.
- `Failure` tipadas (`NetworkFailure`, `ServerFailure`, `CacheFailure`, `AuthFailure` y `ValidationFailure`) y
  `mapDioException`.
- `formatUsd` y `formatSignedUsd`: montos en dólares desde centavos enteros.
- `KeyValueStore` sobre hive_ce, para la caché de divisas y el estado del onboarding.
- Interfaz `Telemetry` (por defecto, `NoopTelemetry`) y, en `core/testing.dart`, `RecordingTelemetry` para los tests.
