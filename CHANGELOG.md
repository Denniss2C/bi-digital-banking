# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y el proyecto se adhiere a [Versionado Semántico](https://semver.org/lang/es/).

Cada PR debe agregar su entrada en la sección **[Unreleased]** bajo la categoría
correspondiente: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## [Unreleased]

### Added
- E2E del flujo crítico (`integration_test`) contra el Firebase real del flavor dev:
  - recorre login → Inicio → Cuentas → Cuenta de Ahorros → movimientos (dos páginas de Firestore) → logout;
  - `make e2e` lo corre en un emulador o dispositivo con un usuario de prueba, cuyas credenciales van en
    `apps/banking_app/e2e.env.json` (git lo ignora; ver `e2e.env.example.json`);
  - instrucciones en la sección *Pruebas y cobertura* del README.
- Ícono de la app y splash con el logo del diseño (`logo_*`):
  - `NexoLogo` en `design_system`: el logo dibujado como vector, con la geometría medida sobre el diseño;
  - ícono adaptativo de Android (con la silueta para los íconos temáticos de Android 13), ícono de Android 7 e ícono
    de iOS de 1024 px sin canal alfa;
  - splash navy con la marca en Android (antes de Android 12 y desde Android 12) y en iOS; `SplashPage` lo continúa sin
    saltos mientras se restaura la sesión;
  - `make brand-assets` regenera todas las imágenes desde el mismo painter.
- Guion de demo y escenarios de prueba (`docs/demo/guion-demo.md`): preparación, cómo fluye la app, 15 escenarios
  con pasos y resultado esperado, guion del video, dónde tocar ante preguntas en vivo y qué revisar si algo no sale.
- Observabilidad:
  - interfaz `Telemetry` en `core` (con `RecordingTelemetry` para tests en `core/testing.dart`), implementada con
    Firebase en el shell;
  - Crashlytics recibe todos los errores no capturados y los inesperados (componentes SDUI que fallan, apertura de
    cuentas);
  - Performance mide cada llamada HTTP de dio y la traza `transfer_submit`;
  - Analytics registra las pantallas por patrón de ruta y los eventos de negocio y UX (`login`, `transfer_completed`,
    `transfer_failed`, `home_layout`, `feature_unavailable`, `push_opened`…), sin datos personales;
  - el panel de depuración permite enviar un error de prueba y forzar un crash;
  - SLOs, alertas y detección de problemas de UX en `deployment-operations.md` §6.
- Notificaciones push (FCM), con un paquete `notifications` sin UI y un `PushCoordinator` en el shell:
  - al iniciar sesión se pide el permiso y se guarda el token en `users/{uid}.fcmTokens`; al cerrar sesión se quita;
  - tocar una notificación abre su `route` (solo pantallas de la app; sin sesión, después del login);
  - con la app abierta se muestra un aviso con "Ver".
- Panel de depuración: el token FCM, con un botón para copiarlo y enviar mensajes de prueba desde la consola.
- Divisas (`fx_rates`): cotizador con tasas reales de ExchangeRate-API (sin clave, con atribución) según la pantalla
  `divisas_y_remesas_*`: moneda, monto, invertir la conversión y tasas de referencia. Se muestra la tasa media de
  mercado, sin compra/venta inventada. Usa caché stale-while-revalidate en `hive_ce`, con aviso offline,
  "actualizado hace X" y pull to refresh.
- `fx_widget` en la home ("Mercado de divisas"), que abre el cotizador. El flag `feature_fx_enabled` apaga la
  pestaña y el widget.
- ADR-006: proveedor de tasas y estrategia de caché.
- Panel de depuración (solo flavor dev, desde Perfil) para demostrar el comportamiento degradado:
  - modo caos HTTP (latencia, % de fallos y sin red);
  - apagar la red de Firestore, para ver la caché offline y la recuperación;
  - cambiar el segmento del cliente, para ver la home personalizada en vivo;
  - ver los flags de Remote Config y pedir valores.
- `accounts`: `setSegment` (herramienta de dev; en producción el segmento lo asignaría el servidor).
- Personalización con Remote Config: la home llega por segmento de cliente (`users/{uid}.segment`, enviado como
  *custom signal*) y cambia en vivo al publicar en la consola, sin reiniciar la app. Si Remote Config falla o manda un
  JSON inválido, se usa el layout embebido. Pull to refresh pide los valores más recientes.
- Feature flags remotos: `feature_transfers_enabled` (oculta el botón, bloquea la ruta y los atajos explican que no
  está disponible), `feature_fx_enabled` y `feature_ai_assistant_enabled`.
- Plantilla de Remote Config versionada en `firebase/remoteconfig.template.json`, generada desde
  `firebase/remote-config/*.json` con layouts para `new_user`, `saver` y `traveler`. Targets `make rc-template` y
  `make deploy-rc`. Plantilla publicada el 2026-10-04.
- `accounts`: `watchSegment` para leer el segmento del cliente.
- ADR-005: personalización con Remote Config y el segmento como custom signal.
- Home (Inicio) renderizada por SDUI con el layout embebido en la app, según la pantalla `inicio_*`: saludo, saldo
  total en vivo, atajos, promoción y movimientos recientes de todas las cuentas. Las acciones del servidor solo abren
  pantallas de la app (rutas validadas en el shell) y deslizar hacia abajo recarga cada componente.
- `accounts`: componentes SDUI `balance_card` y `tx_list`. Los movimientos recientes se actualizan solos cuando cambia
  un saldo.
- `sdui`: motor de Server-Driven UI. Contrato JSON versionado (`schemaVersion`), parser tolerante (un componente
  mal formado se omite sin afectar al resto), registry de componentes por tipo (los tipos desconocidos se ignoran),
  renderer con frontera de error por componente, resolución con layout por defecto embebido y acciones declarativas
  (`navigate`, solo rutas internas). Componentes estándar `promo_banner` y `quick_actions`, con textos en es/en,
  tonos semánticos AA y atajos que no se cortan con texto grande.
- ADR-004: Server-Driven UI con un catálogo de componentes de negocio.
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
- El encabezado del onboarding y la barra del login muestran el logo, como en el diseño.
- iOS usa un solo ícono de 1024 px y Xcode genera los demás tamaños (antes había 15 PNG de Flutter).
- La pestaña Divisas deja de ser un placeholder; `ComingSoonPage` pasa a ser `FeatureUnavailablePage`, para cuando
  un flag apaga una función.
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

### Fixed
- `make help` lista también los objetivos con números en el nombre (como `e2e`).
- `resilience.md` §6 pedía publicar un `home_layout` con un JSON roto, pero la consola de Remote Config no lo
  acepta. Ahora usa un layout válido que la app no puede usar (`schemaVersion: 2`).
- Login, registro y movimientos ya no lanzan un `StateError` si la pantalla se cierra mientras una petición está en
  curso (en el login podía pasar con el redirect al iniciar sesión).
- `promo_banner`: el botón ya no lleva un chevron antes del texto (el diseño lo pone después).
- VS Code ya no muestra cientos de errores en `build/ios` y `build/macos` de la raíz. Son copias del código de los
  plugins que deja Swift Package Manager al resolver dependencias (`make bootstrap`); la raíz ahora tiene su propio
  `analysis_options.yaml`, que las excluye.

[Unreleased]: https://github.com/Denniss2C/bi-digital-banking/commits/main
