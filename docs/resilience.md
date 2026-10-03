# Resiliencia

> Estado: diseño acordado; la implementación llega en el Paso 2 (`core`) y en cada feature.

## 1. Estados de pantalla

Toda pantalla maneja cinco estados:

| Estado | Qué ve el usuario |
|--------|-------------------|
| `loading` | Indicador accesible (`AppLoading`) |
| `success` | Datos |
| `empty` | Mensaje explicativo y, si aplica, una acción |
| `error` | `AppErrorView` con botón **Reintentar** |
| `offline` | Datos en caché y aviso de que pueden no estar actualizados |

## 2. Política de reintentos (`RetryInterceptor`)

- **Máximo 3 intentos** (1 original + 2 reintentos). _A confirmar en el Paso 2._
- **Backoff exponencial con jitter**: `delay = random(0, base * 2^intento)`, con un tope máximo.
- **Solo errores transitorios**: timeouts de conexión o recepción, errores de conexión, HTTP 408, 429, 500, 502, 503 y 504.
- **Nunca se reintenta**: 4xx de negocio (400, 401, 403, 404, 422) ni peticiones no idempotentes (POST) salvo que se marquen explícitamente.

## 3. Modo caos (`ChaosInterceptor`)

Solo disponible en el flavor `dev`, configurable en runtime desde el panel de debug:

| Parámetro | Efecto |
|-----------|--------|
| Latencia | Retraso añadido a cada petición |
| % de fallos | Probabilidad de devolver un error transitorio simulado |
| Sin red | Toda petición falla como error de conexión |

El orden de interceptores coloca `Retry` antes que `Chaos`, para que los fallos inyectados
**ejerciten la lógica real de reintentos**.

## 4. Errores tipados

| Failure | Origen |
|---------|--------|
| `NetworkFailure` | Sin conexión, timeouts |
| `ServerFailure` | 5xx o respuesta inválida |
| `CacheFailure` | Lectura o escritura de caché fallida |
| `AuthFailure` | Credenciales inválidas, sesión expirada |

## 5. Offline

- Firestore con persistencia offline habilitada.
- APIs externas: estrategia _network first, cache fallback_ con `hive_ce` y marca de tiempo de la última actualización.
- `connectivity_plus` para mostrar el aviso de conexión. La conectividad es una pista, no una garantía: la verdad la da el resultado de la petición.

## 6. Cómo probarlo

_Pendiente:_ escenarios manuales con el panel de caos y los tests automatizados que los cubren.
