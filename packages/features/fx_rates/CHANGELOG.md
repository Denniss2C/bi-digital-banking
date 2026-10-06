# Changelog de `fx_rates`

Este paquete no se publica por separado: la versión que se entrega es la de la app (ver
[ADR-001](../../../docs/adr/ADR-001-monorepo-modular.md)). El detalle de cada cambio está en el
[CHANGELOG del monorepo](../../../CHANGELOG.md); aquí queda qué trae el paquete en cada versión.

## [0.0.1] - 2026-10-05

Primera versión, incluida en la app 1.0.0.

### Added

- Tasas reales de ExchangeRate-API (acceso abierto, sin clave) con caché stale-while-revalidate en el dispositivo.
- Pantalla Divisas: cotizador, tasas de referencia, antigüedad de los datos y atribución al proveedor.
- Componente SDUI `fx_widget` para la home.
