# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y el proyecto se adhiere a [Versionado Semántico](https://semver.org/lang/es/).

Cada PR debe agregar su entrada en la sección **[Unreleased]** bajo la categoría
correspondiente: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## [Unreleased]

### Added
- Transferencias entre cuentas propias ("A cuentas Nexo"), según la pantalla Transferir del diseño: cuentas de
  origen y destino, montos rápidos, saldo disponible, concepto, costo $0.00 y comprobante. Se abren desde el botón
  "Transferir" de la pestaña Cuentas.
  - Procesamiento real con `runTransaction` de Firestore: valida el saldo con datos frescos, actualiza ambas cuentas
    y registra un movimiento en cada una, todo o nada.
  - Idempotentes: cada transferencia lleva un `transferId`, y reintentarla con el mismo id nunca mueve el dinero dos
    veces (ni por los reintentos internos de Firestore ni por los del usuario).
  - Reglas: cuentas distintas, monto mayor a cero, máximo $5,000.00 por transferencia y concepto de hasta 60
    caracteres. Sin conexión, la pantalla explica que la transferencia necesita internet.
- `core`: `ValidationFailure` para reglas de negocio rechazadas.
- Cuentas (UI): pestaña Cuentas con el saldo total y tarjetas por cuenta, y detalle con saldo en vivo y
  movimientos con scroll infinito. Estados de carga, vacío, error con reintento y offline con aviso. Textos
  propios del feature (es/en).
- `core`: `formatUsd` / `formatSignedUsd`. Design system: `AppOfflineBanner`.
- Cuentas (datos): modelo en Firestore con dinero en centavos, cuentas en tiempo real con aviso de caché,
  movimientos paginados y apertura idempotente de cuentas en el primer inicio de sesión. Persistencia offline
  de Firestore habilitada.
- Reglas de seguridad de Firestore versionadas y desplegadas (`firebase/firestore.rules`) y ADR-003.
- Auth (UI): onboarding de 3 pasos, login y registro según el diseño, recuperar contraseña, sesión persistente,
  redirect del router por sesión (splash → onboarding / login → home) y logout en Perfil. Textos propios del
  feature (`AuthLocalizations`, es/en).
- Script de Melos `gen-l10n`, también incluido en `make gen` y en la verificación de código generado de CI.
- `auth` (datos): `AuthRepository` sobre Firebase Auth (registro, login, recuperar contraseña, logout y sesión
  persistente) con errores tipados, y `OnboardingRepository` local.
- `core`: `AuthErrorCode` en `AuthFailure` y `KeyValueStore` sobre hive_ce.
- ADR-001: monorepo modular con Melos y pub workspaces, e índice de ADRs en `docs/adr/README.md`.
- CI en GitHub Actions: bootstrap, formato, análisis, tests y verificación del código generado en cada push y
  PR a `main`, con los mismos targets del Makefile. Badge de CI en el README.
- App shell: inyección de dependencias con get_it + injectable (el `ChaosController` solo se registra en el
  entorno `dev`), go_router con splash, login (placeholder) y barra inferior de 4 pestañas
  (`StatefulShellRoute`), e i18n con ARB en español (por defecto) e inglés.
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
- `equatable` baja de 3.x a 2.x en todo el monorepo, por compatibilidad con `fake_cloud_firestore`.
- Design system: color semántico `link` (AA) y temas de `TextButton` y `SegmentedButton`.
- El análisis y el formato ignoran `build/`, donde Swift Package Manager deja código fuente de terceros de los
  plugins (antes rompía `make analyze` y `make format-check` en local).
- Tema de la barra de navegación inferior: acento naranja en la píldora indicadora, íconos y textos con contraste AA.
- La app usa los temas del design system (claro y oscuro según el sistema) y registra la licencia de Inter.
- Los nombres visibles de la app adoptan la marca del diseño: "Nexo" (prod) y "Nexo Dev" (dev).
- `CLAUDE.md` incorpora el diseño "Nexo Digital": tokens, reglas de contraste AA, navegación y alcance por pantalla.
- El deployment target de iOS sube a 15.0, que es lo que exige `firebase_core` 4.x.
- `flutter run` sin argumentos arranca el flavor dev (`default-flavor: dev`).
- La app de ejemplo (contador) se reemplaza por una pantalla mínima que muestra el flavor.

[Unreleased]: https://github.com/Denniss2C/bi-digital-banking/commits/main
