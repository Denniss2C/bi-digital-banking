# Arquitectura

Cómo está hecha la app, por qué y hacia dónde puede crecer. Los diagramas son Mermaid y GitHub los muestra
directamente.

| Documento | Contenido |
|-----------|-----------|
| [components.md](components.md) | Componentes, responsabilidades, servicios externos y qué pasa si fallan |
| [dependencies.md](dependencies.md) | Grafo de paquetes, reglas de modularidad (verificadas por un test) y qué compone el shell |
| [flows.md](flows.md) | Arranque, sesión y apertura de cuentas, home personalizada, transferencia, divisas y push |
| [risks-and-scaling.md](risks-and-scaling.md) | Supuestos, riesgos con su mitigación y cómo escala la plataforma |

Las decisiones están en los [ADRs](../adr/README.md); la resiliencia, en [`resilience.md`](../resilience.md); y la
operación, en [`deployment-operations.md`](../deployment-operations.md).

## Principios

- **Un paquete por dominio, compuestos por el shell.** Los features no se conocen: el shell (`apps/banking_app`) arma
  rutas, inyección de dependencias, el registro SDUI y los flujos que cruzan dominios.
- **Clean Architecture por feature.** `presentation` y `data` dependen de `domain`, y el dominio no importa Flutter,
  Firebase ni dio.
- **Errores como valores.** Los repositorios devuelven `Either<Failure, T>` con fallas tipadas (`NetworkFailure`,
  `ServerFailure`, `AuthFailure`, `ValidationFailure`…) y la UI tiene un estado para cada caso.
- **Datos reales, no simulados.** Firebase Auth, Firestore, Remote Config y FCM, y una API pública de divisas.
  Ningún dato de negocio vive en la app: la plantilla de apertura también está en Firestore.
- **Configurable sin publicar.** La home se dibuja desde un JSON de Remote Config (SDUI), con feature flags y
  personalización por segmento en tiempo real.
- **Degradación elegante.** Persistencia offline de Firestore, caché stale-while-revalidate para la API externa,
  reintentos con backoff y avisos de "sin conexión" en vez de pantallas rotas.
- **Observable sin datos personales.** Los features reportan con la interfaz `Telemetry` de `core`; el shell la
  implementa con Crashlytics, Performance y Analytics.
- **Herramientas de desarrollo solo en dev.** El panel de depuración y el modo caos se registran solo en el entorno
  `dev` de la inyección de dependencias: en prod no están registrados ni tienen ruta (lo verifica un test).
