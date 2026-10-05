# core

Lo que comparten todos los paquetes: red resiliente, errores tipados, formato de montos, almacenamiento local y
telemetría. No depende de ningún paquete interno. Dueño: `@team-platform`.

## Uso

```dart
import 'package:core/core.dart';

// Cliente HTTP para APIs externas: reintentos siempre, caos solo en dev.
final dio = createDioClient(baseUrl: 'https://open.er-api.com', chaos: chaosOrNull);

// En el repositorio de un feature (con fpdart): errores como valores, nunca
// excepciones fuera de `data`.
try {
  await dio.get<Object?>('/v6/latest/USD');
} on DioException catch (error) {
  return Left(mapDioException(error)); // NetworkFailure, ServerFailure…
}

formatUsd(490029);                        // $4,900.29
await store.write('fx.rates', json);      // KeyValueStore (hive_ce)
telemetry.event('transfer_completed');    // Telemetry, sin datos personales
```

## Qué incluye

| Pieza | Para qué |
|-------|----------|
| `createDioClient` | Cliente dio con `RetryInterceptor` y, si se le pasa un `ChaosController`, `ChaosInterceptor` |
| `RetryInterceptor` + `RetryPolicy` | Reintenta errores transitorios (de red, 408, 429, 500, 502, 503 y 504) en métodos idempotentes: 3 intentos, backoff exponencial con jitter y tope de 4 s |
| `ChaosInterceptor` + `ChaosController` | Latencia, fallos 503 y "sin red" inyectados en runtime desde el panel de depuración. Los fallos pasan por los reintentos, como uno real |
| `mapDioException` | Traduce un `DioException` a una `Failure` tipada |
| `Failure` | Clase `sealed`: `NetworkFailure`, `ServerFailure`, `CacheFailure`, `AuthFailure` y `ValidationFailure`. La UI elige el mensaje con un `switch` exhaustivo |
| `formatUsd`, `formatSignedUsd` | Montos en dólares desde centavos enteros (nunca `double` para dinero) |
| `KeyValueStore` / `HiveKeyValueStore` | Almacenamiento local simple: caché de divisas y estado del onboarding |
| `Telemetry` | Interfaz de monitoreo (eventos, pantallas, errores, trazas y usuario). El shell la implementa con Firebase; `NoopTelemetry` es el valor por defecto |

`package:core/testing.dart` trae dobles para los tests de cualquier paquete: `RecordingTelemetry` guarda todo lo
reportado para verificarlo.

## Reglas

- **Sin paquetes internos:** `core` no conoce features, UI ni Firebase. Lo verifica el test de reglas de arquitectura.
- **Algo entra a `core` solo si lo usan varios paquetes.** Lo de un solo dominio vive en su feature.

Detalle de reintentos y caos: [`docs/resilience.md`](../../docs/resilience.md).

## Tests

```bash
cd packages/core && flutter test
```

Son deterministas: un adaptador HTTP falso responde con resultados programados, y el `Random` y las esperas se
inyectan.
