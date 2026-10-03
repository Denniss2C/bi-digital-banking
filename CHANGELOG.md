# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y el proyecto se adhiere a [Versionado Semántico](https://semver.org/lang/es/).

Cada PR debe agregar su entrada en la sección **[Unreleased]** bajo la categoría
correspondiente: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## [Unreleased]

### Added
- `design_system`: tokens de "Nexo Digital", temas claro y oscuro (Material 3) con la fuente Inter empaquetada y
  componentes accesibles: `AppButton`, `AppCard`, `AppLoading`, `AppErrorView` y `AppEmptyView`.
- Tests de contraste WCAG AA en ambos temas y de texto escalado al 200%.
- `core`: cliente HTTP (`createDioClient`) con `RetryInterceptor` (3 intentos, backoff exponencial con jitter,
  solo errores transitorios y métodos idempotentes) y `ChaosInterceptor` configurable en runtime
  (latencia, % de fallos, sin red).
- `core`: `Failure` tipados (`NetworkFailure`, `ServerFailure`, `CacheFailure`, `AuthFailure`) y `mapDioException`.
- Referencia visual de diseño "Nexo Digital" (Stitch) en `docs/design/`: tokens de color, tipografía,
  formas y espaciado, más 7 pantallas de referencia.
- Flavors `dev` y `prod`: product flavors en Android, configuraciones de build y schemes en iOS,
  entry points `main_dev.dart` / `main_prod.dart`, `AppConfig` y una app de Firebase por flavor.
- Cinta `DEV` y flag `enableDebugTools`, activos solo en dev.
- ADR-002: entornos con flavors sobre un único proyecto Firebase.
- Configuraciones de ejecución de VS Code para cada flavor.
- Makefile con los comandos de desarrollo (`setup`, `bootstrap`, `gen`, `analyze`,
  `format`, `test`, `coverage`, `run-*`, `build-apk-*`).
- Estructura de documentación: `docs/architecture`, `docs/adr` (plantilla ADR-000),
  `docs/deployment-operations.md`, `docs/resilience.md` y bitácora `docs/ai/AI_USAGE.md`.
- Plantilla de Pull Request y `CODEOWNERS` con un equipo responsable por dominio.
- Monorepo con Dart pub workspaces y scripts de Melos 8 (`analyze`, `test`, `format`,
  `build_runner`) declarados en el `pubspec.yaml` raíz.
- Grafo de dependencias entre paquetes: `core` → `design_system` → `sdui` → `features/*` → `banking_app`.
- Scaffolding inicial: app shell `apps/banking_app`, paquetes `core`, `design_system`,
  `sdui` y features `auth`, `accounts`, `notifications`, `fx_rates`.
- Configuración de Firebase con FlutterFire CLI.

### Changed
- La app usa los temas del design system (claro y oscuro según el sistema) y registra la licencia de Inter.
- Los nombres visibles de la app adoptan la marca del diseño: "Nexo" (prod) y "Nexo Dev" (dev).
- `CLAUDE.md` incorpora el diseño "Nexo Digital": tokens, reglas de contraste AA, navegación y alcance por pantalla.
- El deployment target de iOS sube a 15.0, que es lo que exige `firebase_core` 4.x.
- `flutter run` sin argumentos arranca el flavor dev (`default-flavor: dev`).
- La app de ejemplo (contador) se reemplaza por una pantalla mínima que muestra el flavor.

[Unreleased]: https://github.com/Denniss2C/bi-digital-banking/commits/main
