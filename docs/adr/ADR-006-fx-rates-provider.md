# ADR-006: Divisas con una API pública sin clave y caché stale-while-revalidate

- **Estado:** Aceptado
- **Fecha:** 2026-10-04
- **Autores:** @Denniss2C
- **Equipos afectados:** @team-fx, @team-platform

## Problema

La plataforma debe integrar **al menos un servicio o micro app externa relevante**, con datos reales: la prueba
descarta las respuestas estáticas. Además, la integración tiene que degradarse con elegancia cuando el servicio no
responde, y **no puede haber secretos en el código**.

Para una banca en dólares (Ecuador), un cotizador de divisas es útil y fácil de demostrar.

## Alternativas

| Alternativa | A favor | En contra |
|-------------|---------|-----------|
| A. **ExchangeRate-API, acceso abierto** (`open.er-api.com`) | Sin clave ni registro. 166 monedas con base USD, incluidas COP, PEN y MXN. Los términos permiten guardar en caché. | Se actualiza una vez al día, pide atribución visible y limita a una consulta por hora (429 si se excede). |
| B. Frankfurter (tasas del BCE) | Sin clave y de una fuente oficial. | Unas 30 monedas, base EUR, sin COP ni PEN. |
| C. API de pago con clave (por ejemplo, tasas en tiempo real) | Más frecuencia y monedas. | La clave sería un secreto dentro de la app; habría que poner un backend propio delante. |
| D. Tasas cargadas en Firestore | Control total. | Son datos que alguien tiene que mantener: en la práctica, datos simulados. |

## Decisión

**Alternativa A**, con caché **stale-while-revalidate** en el dispositivo (`KeyValueStore` de `core` sobre hive_ce):

- **Primero la caché.** Las tasas guardadas se muestran al instante.
- **Consultar solo si sirve:** cuando el proveedor ya publicó tasas nuevas (`time_next_update_unix`) y pasó al menos
  1 h desde la última consulta. Así se respeta el límite del proveedor.
- **Pull to refresh fuerza la consulta**, que es lo que permite ver el modo caos en la demo.
- **Si la consulta falla**, siguen las tasas guardadas con el motivo (aviso offline). Si no hay nada guardado, error
  con reintento.
- **HTTP con dio:** pasa por `RetryInterceptor` y, solo en dev, por `ChaosInterceptor` (ADR-002 y `resilience.md`).
- **Tasa media, sin compra/venta.** La API entrega la tasa media de mercado. Se muestra así ("1 USD = 0.8888 EUR"),
  aclarando que no es una cotización de compra o venta: inventar un margen sería mostrar datos falsos.
- **Atribución** "Rates By Exchange Rate API" visible, como piden sus términos.
- **`feature_fx_enabled`** apaga la pestaña y el `fx_widget` de la home sin publicar la app.

## Trade-offs

- **Tasas del día, no en tiempo real.** Para un cotizador de referencia alcanza, y la pantalla dice cuándo se
  publicaron ("Actualizado hace X horas"). Un banco operaría con su propia tesorería.
- **Límite de consultas por IP.** Un uso intenso compartido podría recibir 429. Lo cubren el reintento y la caché, y
  en producción un backend propio centralizaría las consultas.
- **Sin operación real.** "Operar y enviar divisas" y los monederos del diseño quedan fuera: requerirían un core
  bancario.

## Impacto a largo plazo

- **Cambiar de proveedor** solo toca `ExchangeRateApiRepository` (el parser y la URL). La pantalla, el widget y la
  caché dependen de `FxRatesRepository`.
- **Un proveedor con clave** iría detrás de un backend propio (o una Cloud Function), nunca en la app.
- **Compra/venta reales** vendrían de la tesorería del banco, como otra implementación del mismo repositorio.
