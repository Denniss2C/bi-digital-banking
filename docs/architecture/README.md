# Arquitectura

Diagramas en Mermaid (se renderizan directamente en GitHub). Leyenda de estado en cada diagrama:
los nodos con borde punteado están **planificados**; los de borde sólido ya están **implementados**.

| Documento | Contenido |
|-----------|-----------|
| [components.md](components.md) | Componentes de la plataforma y servicios externos |
| [dependencies.md](dependencies.md) | Grafo de dependencias entre paquetes y reglas de modularidad |
| [flows.md](flows.md) | Flujos clave: arranque, petición resiliente, render SDUI |

## Principios

- **Clean Architecture por feature**: `data` → `domain` ← `presentation`. El dominio no conoce Flutter, Firebase ni dio.
- **Features aislados**: un feature solo depende de `core`, `design_system` y `sdui`. La comunicación entre features pasa por el shell (rutas y contratos inyectados).
- **Errores como valores**: los repositorios devuelven `Either<Failure, T>` (fpdart); las excepciones no cruzan la capa `data`.
- **Offline first**: Firestore con persistencia offline y caché local con `hive_ce` para APIs externas.
