# Changelog de `accounts`

Este paquete no se publica por separado: la versión que se entrega es la de la app (ver
[ADR-001](../../../docs/adr/ADR-001-monorepo-modular.md)). El detalle de cada cambio está en el
[CHANGELOG del monorepo](../../../CHANGELOG.md); aquí queda qué trae el paquete en cada versión.

## [0.0.1] - 2026-10-05

Primera versión, incluida en la app 1.0.0.

### Added

- Cuentas, saldos y movimientos en Cloud Firestore, con el dinero en centavos enteros y persistencia offline.
- Movimientos paginados con un cursor opaco, para que el dominio no dependa de Firestore.
- Apertura de cuentas idempotente desde la plantilla `templates/opening`.
- Transferencias entre cuentas propias con `runTransaction`, idempotentes (`transferId`) y con un límite de $5,000.00.
- Pantallas de cuentas, movimientos y transferencia, con estados de carga, vacío, error con reintento y sin conexión.
- Componentes SDUI `balance_card` y `tx_list` para la home.
