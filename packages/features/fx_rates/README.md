# fx_rates

Divisas de Nexo: un cotizador con tasas reales de una API pública, caché en el dispositivo y el componente `fx_widget`
para la home. Dueño: `@team-fx`. Depende de `core`, `design_system` y `sdui`; el shell lo compone.

Decisión y alternativas: [ADR-006](../../../docs/adr/ADR-006-fx-rates-provider.md).

## Datos

- **Proveedor:** [ExchangeRate-API](https://www.exchangerate-api.com), acceso abierto (`https://open.er-api.com/v6/latest/USD`).
  No necesita clave; pide atribución ("Rates By Exchange Rate API", visible en la pantalla) y como mucho una consulta
  por hora.
- **Tasa media de mercado** (unidades de cada moneda por 1 USD). No hay compra/venta y no se inventa ningún margen.
- **Caché stale-while-revalidate** (`ExchangeRateApiRepository.watchRates`):

  | Situación | Qué emite |
  |-----------|-----------|
  | Hay caché y el proveedor todavía no publicó tasas nuevas | La caché, sin llamar a la red |
  | Hay caché, el proveedor publicó tasas nuevas y pasó 1 h desde la última consulta | La caché (`isRefreshing`) y después las tasas nuevas |
  | La consulta falla | La caché con `refreshFailure` (aviso offline) |
  | No hay caché y la consulta falla | `Left(failure)` → error con reintento |
  | `forceRefresh` (pull to refresh) | Consulta siempre |

  La caché guarda la respuesta cruda y la hora de la consulta en el `KeyValueStore` de `core` (hive_ce). Si está
  corrupta, se ignora y la próxima consulta la reescribe.
- **HTTP:** el shell crea el cliente con `createDioClient`, que trae reintentos y, en dev, el modo caos.

## Presentación

- **`FxPage`** (pestaña Divisas), según la pantalla `divisas_y_remesas_*`:
  - estado de las tasas;
  - cotizador: moneda, monto, invertir la conversión y "1 USD = X";
  - tasas de referencia;
  - cuándo se publicaron, la aclaración de tasa media y la atribución;
  - estados de carga, error con reintento y offline con las tasas guardadas;
  - pull to refresh.
- **`fx_widget`** (`fxSduiComponents`): "Mercado de divisas" en la home. Props: `currencies` (códigos ISO, hasta 4;
  por defecto EUR, COP y PEN) y `action` (por ejemplo, abrir Divisas).
- Fuera de alcance, como dice el diseño: operar, monederos, remesas y canales.

## Tests

```bash
cd packages/features/fx_rates && flutter test
```

Cubren el parser, la caché (al día, vencida, el mínimo de 1 h, forzada, fallo con y sin caché, y caché corrupta), la
conversión y el formato, el cubit, la pantalla y el widget.
