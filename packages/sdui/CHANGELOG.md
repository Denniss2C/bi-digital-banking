# Changelog de `sdui`

Este paquete no se publica por separado: la versión que se entrega es la de la app (ver
[ADR-001](../../docs/adr/ADR-001-monorepo-modular.md)). El detalle de cada cambio está en el
[CHANGELOG del monorepo](../../CHANGELOG.md); aquí queda qué trae el paquete en cada versión.

## [0.0.1] - 2026-10-05

Primera versión, incluida en la app 1.0.0.

### Added

- Contrato JSON con `schemaVersion` e `id` opcional, textos por idioma y acciones `navigate` solo hacia rutas internas.
- `SduiRegistry`, `SduiView` y `resolveSduiLayout`: los tipos desconocidos y los componentes inválidos se omiten sin
  romper la pantalla, y un documento inválido cae al layout por defecto embebido.
- Componentes estándar `promo_banner` y `quick_actions`, con tonos semánticos en vez de colores crudos.
