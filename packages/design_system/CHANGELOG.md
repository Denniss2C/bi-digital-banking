# Changelog de `design_system`

Este paquete no se publica por separado: la versión que se entrega es la de la app (ver
[ADR-001](../../docs/adr/ADR-001-monorepo-modular.md)). El detalle de cada cambio está en el
[CHANGELOG del monorepo](../../CHANGELOG.md); aquí queda qué trae el paquete en cada versión.

## [0.0.1] - 2026-10-05

Primera versión, incluida en la app 1.0.0.

### Added

- Tokens del diseño Nexo: colores, grilla de 8 pt, áreas táctiles de 48 px, radios y sombras.
- Inter empaquetada (sin descargas), con cifras tabulares para los montos.
- Temas claro y oscuro con la extensión `AppSemanticColors`, y contraste AA verificado por tests.
- Componentes accesibles: `AppButton`, `AppCard`, `AppLoading`, `AppErrorView`, `AppEmptyView` y `AppOfflineBanner`.
- `NexoLogo`: el logo vectorial con el que se generan el ícono y el splash.
