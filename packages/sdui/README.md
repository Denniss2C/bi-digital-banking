# sdui

Motor de **Server-Driven UI** de Nexo: el servidor describe una pantalla en JSON y la app la arma con componentes
propios, diseñados, accesibles y testeados. Así se cambian el orden, el contenido y las campañas **sin publicar una
versión nueva**. Dueño: `@team-sdui`. Depende de `core` y `design_system`.

La decisión y sus alternativas están en [ADR-004](../../docs/adr/ADR-004-sdui-engine.md).

## Contrato JSON

```json
{
  "schemaVersion": 1,
  "components": [
    { "type": "balance_card" },
    {
      "type": "quick_actions",
      "props": {
        "title": { "es": "Operaciones frecuentes", "en": "Frequent actions" },
        "items": [
          { "label": "Transferir", "icon": "send", "highlighted": true,
            "action": { "type": "navigate", "route": "/accounts/transfer" } },
          { "label": "Divisas", "icon": "fx",
            "action": { "type": "navigate", "route": "/fx" } }
        ]
      }
    },
    {
      "type": "promo_banner",
      "id": "promo-ahorro-flexible",
      "props": {
        "eyebrow": "Nexo Ahorro Flexible",
        "title": "¡Tu rendimiento subió al 8.5% anual!",
        "body": "Sin plazos forzosos y respaldado por COSEDE.",
        "tone": "primary",
        "icon": "trending_up",
        "cta": { "label": "Simular ahora", "action": { "type": "navigate", "route": "/accounts" } }
      }
    }
  ]
}
```

| Campo | Tipo | Notas |
|-------|------|-------|
| `schemaVersion` | entero ≥ 1 | Opcional (por defecto 1). Esta versión de la app entiende hasta la **1**. |
| `components` | lista | Se muestran en orden, de arriba hacia abajo. |
| `type` | string | Tipo de componente (ver catálogo). |
| `id` | string | Opcional. Mantiene el estado del componente si el servidor cambia el orden, y lo identifica en logs y analítica. |
| `props` | objeto | Opcional. Depende del tipo. |

- **Textos:** un string o un objeto por idioma (`{"es": "...", "en": "..."}`). Se usa el idioma de la app, después
  español y después cualquier traducción disponible.
- **Acciones:** por ahora solo `{"type": "navigate", "route": "/ruta"}`, con rutas internas (empiezan con `/`; nunca
  `//host` ni `https://`). La app decide cómo ejecutarlas.
- **Colores:** el servidor elige un tono semántico (`tone`), nunca colores crudos. Así el contraste AA lo garantiza
  el design system en ambos temas.

## Qué pasa cuando el JSON trae algo inesperado

| Situación | Comportamiento |
|-----------|----------------|
| Tipo de componente desconocido | Se omite. Una app vieja ignora los componentes nuevos (forward compatibility). |
| Componente mal formado (sin `type`, `props` que no es objeto) | Se omite y se reporta; el resto de la pantalla se muestra. |
| Prop obligatoria faltante (p. ej. `promo_banner` sin `title`) | Se omite solo ese componente y se reporta. |
| Acción desconocida o ruta externa | El botón o el atajo no se muestran: nunca hay botones que no hacen nada. |
| `id` repetido | Se muestra igual; el segundo usa su posición como clave. |
| No es JSON, forma incorrecta o `schemaVersion` mayor | Se descarta el documento y se usa el **layout por defecto** embebido en la app. |
| Ningún componente que esta app sepa mostrar | Igual: layout por defecto, para no mostrar una pantalla vacía. |

Los motivos llegan en `SduiLayout.issues` y `SduiResolvedLayout.issues`, para logs y analítica. Nunca se muestran al
usuario.

## Catálogo

Componentes estándar (`standardSduiComponents`, no necesitan datos de ningún feature):

**`promo_banner`**: campaña o contenido.

| Prop | Tipo | |
|------|------|-|
| `title` | texto | **Obligatorio** |
| `eyebrow`, `body`, `footnote` | texto | Opcionales |
| `icon` | string | Nombre de la lista de íconos |
| `tone` | `primary` · `secondary` · `neutral` | Naranja claro (por defecto), navy o blanco |
| `cta` | `{"label", "action"}` | Botón; se oculta si la acción no está soportada |

**`quick_actions`**: atajos ("Operaciones frecuentes").

| Prop | Tipo | |
|------|------|-|
| `title` | texto | Opcional |
| `items` | lista de `{"label", "icon", "action", "highlighted"}` | Se omiten los ítems sin `label` o con una acción no soportada. Sin ítems válidos, se omite el componente. |

Muestra cuatro atajos por fila, como el diseño. Con texto grande (más de 130%), pasa a dos por fila para que las
etiquetas no se corten.

**Íconos** (`sduiIcons`): `transfer`, `send`, `accounts`, `fx`, `savings`, `trending_up`, `card`, `bill`, `qr`,
`atm`, `gift`, `travel`, `shield`, `notifications`, `profile`, `info` y `star`. Un nombre desconocido muestra un
ícono neutro.

Los componentes con datos los registra el feature dueño de esos datos:

| Tipo | Feature | Props |
|------|---------|-------|
| `balance_card` | accounts | `action`: al tocar la tarjeta (por ejemplo, abrir Cuentas) |
| `tx_list` | accounts | `title`, `limit` (1 a 10; por defecto 5) y `action` (enlace "Ver todos") |
| `fx_widget` | fx_rates | _Pendiente_ (`feat/fx-rates`); hasta entonces se omite |

## Uso

```dart
final registry = SduiRegistry(standardSduiComponents)
  ..registerAll(accountsComponents); // cada feature aporta los suyos

final resolved = resolveSduiLayout(
  remote: remoteConfig.getString('home_layout'),
  fallback: defaultHomeLayout, // JSON embebido en la app
  registry: registry,
);
// resolved.source (remote / fallback) y resolved.issues → logs y analítica

SduiView(
  layout: resolved.layout,
  registry: registry,
  onAction: (action) => switch (action) {
    SduiNavigateAction(:final route) => context.go(route),
  },
  onComponentError: (node, error, stack) => log(...),
);
```

`SduiView` no hace scroll: la pantalla que lo contiene decide cómo (por ejemplo, con pull to refresh).

Los layouts de la home viven en `firebase/remote-config/` (uno por segmento) y llegan por Remote Config; cómo
cambiarlos sin publicar la app está en [`deployment-operations.md`](../../docs/deployment-operations.md) §7.

## Agregar un componente (otro equipo)

1. Escribe el widget y un `fromProps` que **lea y valide los props** con `SduiProps`. Si falta algo obligatorio,
   lanza `SduiPropsException`. Valida ahí y no dentro de `build`: así el motor puede omitir solo ese componente.
2. Expórtalo como `Map<String, SduiComponentBuilder>` desde tu feature.
3. El shell lo registra con `registry.registerAll(...)`. Si dos features registran el mismo tipo, falla al arrancar:
   es un error de integración, no algo a resolver en runtime.
4. Agrega tests del componente (props válidos, faltantes y accesibilidad) y documenta sus props en esta tabla.

Un tipo nuevo sí requiere publicar la app. Mientras tanto, las versiones anteriores lo ignoran.

## Tests

```bash
cd packages/sdui && flutter test
```

Cubren parser, props, acciones, registry, resolución con fallback, renderer (orden, errores aislados, estado al
reordenar e ids repetidos), componentes y contraste AA de cada tono en ambos temas.
