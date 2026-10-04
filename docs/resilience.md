# Resiliencia

> Estado: implementados la red resiliente de `core` (reintentos, modo caos y errores tipados), los 5 estados en
> Cuentas, Transferir e Inicio, la caché offline de Firestore, el fallback de la home (Remote Config y SDUI) y el
> panel de depuración (solo dev) y la caché stale-while-revalidate de la API externa (Divisas).

## 1. Estados de pantalla

Toda pantalla maneja cinco estados:

| Estado | Qué ve el usuario |
|--------|-------------------|
| `loading` | Indicador accesible (`AppLoading`) |
| `success` | Datos |
| `empty` | Mensaje explicativo y, si aplica, una acción |
| `error` | `AppErrorView` con botón **Reintentar** |
| `offline` | Datos en caché y aviso de que pueden no estar actualizados |

**Implementado en Cuentas** (`AccountsPage` y `AccountDetailPage`):
- el aviso offline sale de `metadata.isFromCache` de Firestore;
- la carga de más páginas falla sin perder lo ya cargado.

**Transferir:** carga de cuentas, error con salida a Cuentas, errores por campo después del primer intento y un
mensaje claro sin conexión.

**Inicio:** cada componente maneja sus estados. Sin conexión, el saldo y los movimientos muestran los datos guardados
con su aviso. Si el layout remoto falta o está roto, se usa el embebido, y un componente inválido se omite sin afectar
al resto.

**Pantallas que se cierran durante una petición** (por ejemplo, el login, que se cierra con el redirect apenas la
sesión cambia): la respuesta que llega tarde se descarta, en vez de lanzar un `StateError`.

## 2. Política de reintentos (`RetryInterceptor`)

Implementada en `packages/core/lib/src/network/retry_interceptor.dart` (`RetryPolicy` + `RetryInterceptor`).

- **3 intentos en total**: 1 original + 2 reintentos (`RetryPolicy.maxAttempts`).
- **Backoff exponencial con *full jitter***: `espera = random(0, min(4 s, 400 ms × 2^(reintento − 1)))`.
  El primer reintento espera hasta 400 ms y el segundo hasta 800 ms. El azar evita que muchos clientes que
  fallaron a la vez reintenten sincronizados.
- **Solo errores transitorios**: timeouts (conexión, envío y recepción), errores de conexión y HTTP 408, 429, 500,
  502, 503 y 504.
- **Nunca se reintenta**:
  - los 4xx de negocio (400, 401, 403, 404, 422), las cancelaciones ni los errores de certificado;
  - los métodos **no idempotentes**: solo se reintentan GET, HEAD, OPTIONS, PUT y DELETE, así un POST nunca se envía dos veces.
- Cada reintento vuelve a pasar por `dio.fetch`, es decir, por **todos** los interceptores (incluido el caos).
- Si se agotan los intentos, el último `DioException` se convierte en un `Failure` tipado con `mapDioException`.

### Transferencias: reintentos sin cobros dobles

Las transferencias no pasan por dio, sino por `runTransaction` de Firestore, que tiene su propio riesgo: si el commit
llega al servidor pero la respuesta se pierde, el SDK **reintenta la transacción**, y el reintento lee saldos que ya
incluyen la primera transferencia. Lo mismo pasa si el usuario reintenta después de un "Sin conexión".

- Cada transferencia lleva un `transferId` (clave de idempotencia). El formulario lo pide una vez y lo reutiliza en
  cada reintento; cualquier cambio en el formulario genera uno nuevo.
- Los dos movimientos usan ese id como id de documento. Dentro de la transacción, si el débito ya existe, el
  repositorio devuelve el comprobante original y no escribe nada.
- Tests: el mismo id enviado dos veces mueve el dinero una sola vez (repositorio), y un reintento reutiliza el id
  (cubit). Los dos se comprobaron con mutaciones.

## 3. Modo caos (`ChaosInterceptor`)

Solo disponible en el flavor `dev`, configurable en runtime desde el panel de debug:

| Parámetro (`ChaosConfig`) | Efecto |
|-----------|--------|
| `latency` | Retraso añadido a cada petición |
| `failureRate` (0–1) | Probabilidad de responder con un **HTTP 503** inyectado |
| `offline` | Toda petición falla como error de conexión, sin salir del dispositivo |

- La configuración vive en un `ChaosController` (`ValueNotifier<ChaosConfig>`). El interceptor la lee en cada
  petición, así que los cambios desde el panel de debug aplican de inmediato.
- `core` no sabe de flavors: `createDioClient` solo agrega el `ChaosInterceptor` si recibe un `ChaosController`,
  y el shell solo lo pasa en dev (`AppConfig.enableDebugTools`).
- **Detalle de dio que hace funcionar la demo.** Si un interceptor rechaza en `onRequest` con
  `handler.reject(error)`, dio **no** ejecuta los `onError` del resto. El caos rechaza con
  `handler.reject(error, true)`, igual que dio con un error real de red. Así el `RetryInterceptor` ve los fallos
  inyectados y los reintenta. Hay un test que lo verifica, y se comprobó que falla si se quita el `true`.

## 4. Errores tipados

| Failure | Origen |
|---------|--------|
| `NetworkFailure` | Sin conexión, timeouts |
| `ServerFailure` | 5xx o respuesta inválida |
| `CacheFailure` | Lectura o escritura de caché fallida |
| `AuthFailure` | Credenciales inválidas, sesión expirada |
| `ValidationFailure` | Regla de negocio rechazada (por ejemplo, saldo insuficiente); el feature define el código |

## 5. Offline

- Firestore con persistencia offline habilitada. El panel de depuración puede apagar su red para mostrarlo sin
  activar el modo avión.
- **Las transferencias necesitan el servidor.** Las transacciones de Firestore no se encolan sin conexión: fallan
  (`unavailable`), se traducen a `NetworkFailure` y la pantalla lo explica. Nunca queda nada escrito a medias.
- **API externa (Divisas): stale-while-revalidate** con `hive_ce`. Las tasas guardadas se muestran al instante y la
  red se consulta solo si el proveedor ya publicó tasas nuevas y pasó al menos 1 h (lo que pide para no responder 429).
  Si falla, siguen las guardadas con aviso y "Actualizado hace X"; si no hay nada guardado, error con reintento.
  Detalle en [ADR-006](adr/ADR-006-fx-rates-provider.md).
- **El aviso offline sale de los datos**, no de un detector de conectividad. Firestore informa si lo que muestra viene
  de la caché (`isFromCache`), y eso es lo que se le dice al usuario. Se descartó `connectivity_plus`: la conectividad
  es una pista (hay wifi sin internet), mientras que la respuesta real de cada petición es la verdad.

## 6. Cómo probarlo

### Tests automatizados (`packages/core/test/network/`)

Son deterministas: un adaptador HTTP falso responde con resultados programados, y el `Random` y las esperas se
inyectan, así que no hay red real ni esperas.

| Escenario | Test |
|-----------|------|
| 503 transitorio → reintenta y devuelve la respuesta buena | `retry_interceptor_test.dart` |
| 3 fallos → se rinde y propaga el último error | `retry_interceptor_test.dart` |
| Errores de conexión y timeouts → reintenta | `retry_interceptor_test.dart` |
| 404 o POST → no reintenta | `retry_interceptor_test.dart` |
| Backoff exponencial, jitter y tope | `retry_interceptor_test.dart` |
| Caos apagado, sin red, 100% de fallos y latencia | `chaos_interceptor_test.dart` |
| Cambio de configuración en runtime | `chaos_interceptor_test.dart` |
| Fallo inyectado por el caos → lo reintenta el `RetryInterceptor` | `chaos_interceptor_test.dart` |
| `DioException` → `Failure` tipado | `dio_failure_mapper_test.dart` |

### Escenarios manuales (guion de demo)

Estos son los escenarios de resiliencia; el guion completo de la app está en
[`docs/demo/guion-demo.md`](demo/guion-demo.md).

Con `make run-dev`, en **Perfil → Panel de depuración** (solo existe en el flavor dev):

| # | Qué hacer | Qué se ve |
|---|-----------|-----------|
| 1 | Apagar **Firestore conectado** | Cuentas muestra los datos guardados con el aviso offline. En Inicio, el saldo dice "Sin conexión". Transferir explica que necesita internet y no escribe nada a medias. |
| 2 | Volver a encender Firestore | Los datos se sincronizan solos y los avisos desaparecen, sin reintentos manuales. |
| 3 | Cambiar el **segmento** a `traveler` y después a `saver` | La home cambia de orden, promoción y atajos en segundos, sin reiniciar (Remote Config con el custom signal). |
| 4 | En la consola de Remote Config, publicar un `home_layout` que la app no pueda usar, como `{"schemaVersion": 2, "components": []}` (la consola no acepta un JSON mal escrito) | La home sigue con el layout embebido. Un componente con props inválidas se omite solo. |
| 5 | Poner `feature_transfers_enabled` en `false` y publicar | Desaparece el botón Transferir. El atajo de la home explica que no está disponible y la ruta redirige a Cuentas. |
| 6 | **Modo caos HTTP**: latencia de 3 s, 50% de fallos o sin red; después, en **Divisas**, deslizar hacia abajo | Con latencia, la pantalla sigue mostrando las tasas guardadas mientras espera. Con fallos, los reintentos los absorben (se ven en los logs). Sin red, aparece el aviso offline con las tasas guardadas. Al apagar el caos y deslizar de nuevo, se recupera. |
| 7 | Modo avión con la app abierta | Lo mismo que el escenario 1, más Remote Config con los últimos valores activos. |

El panel no se compila en prod: el router de prod no tiene la ruta y la inyección de dependencias no registra sus
herramientas (lo verifica `test/di/injection_test.dart`).
