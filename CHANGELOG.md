# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y el proyecto se adhiere a [Versionado Semántico](https://semver.org/lang/es/).

Cada PR debe agregar su entrada en la sección **[Unreleased]** bajo la categoría
correspondiente: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## [Unreleased]

### Added
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

[Unreleased]: https://github.com/Denniss2C/bi-digital-banking/commits/main
