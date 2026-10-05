# Decisiones de arquitectura (ADR)

Cada decisión importante se registra con la [plantilla ADR-000](ADR-000-template.md): problema, alternativas,
decisión, trade-offs e impacto a largo plazo. Los ADR no se reescriben: si una decisión cambia, se crea uno nuevo que
reemplaza al anterior.

| ADR | Decisión | Estado |
|-----|----------|--------|
| [ADR-001](ADR-001-monorepo-modular.md) | Monorepo modular con Melos y pub workspaces | Aceptado |
| [ADR-002](ADR-002-flavors-firebase.md) | Entornos dev/prod con flavors sobre un único proyecto Firebase | Aceptado |
| [ADR-003](ADR-003-accounts-firestore.md) | Datos bancarios en Firestore con escrituras desde el cliente (plan Spark) | Aceptado (la apertura, en ADR-007) |
| [ADR-004](ADR-004-sdui-engine.md) | Server-Driven UI con un catálogo de componentes de negocio | Aceptado |
| [ADR-005](ADR-005-remote-config-personalization.md) | Personalización con Remote Config y el segmento como custom signal | Aceptado |
| [ADR-006](ADR-006-fx-rates-provider.md) | Divisas con una API pública sin clave y caché stale-while-revalidate | Aceptado |
| [ADR-007](ADR-007-opening-template.md) | Plantilla de apertura de cuentas en Firestore, publicada con `gcloud` | Aceptado (reemplaza la apertura de ADR-003) |
