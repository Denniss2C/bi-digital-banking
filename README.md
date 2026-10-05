# Nexo Banco Digital

[![CI](https://github.com/Denniss2C/bi-digital-banking/actions/workflows/ci.yml/badge.svg)](https://github.com/Denniss2C/bi-digital-banking/actions/workflows/ci.yml)

Plataforma financiera 100 % digital en Flutter para Ecuador, con la marca ficticia **Nexo**. Es una prueba técnica
para Banco Internacional (Ecuador). La identidad visual está en [`docs/design/`](docs/design/DESIGN.md).

## Tabla de contenidos

1. [Visión general](#visión-general)
2. [Arquitectura](#arquitectura)
3. [Estructura del monorepo](#estructura-del-monorepo)
4. [Requisitos previos](#requisitos-previos)
5. [Puesta en marcha](#puesta-en-marcha)
6. [Flavors y configuración](#flavors-y-configuración)
7. [Comandos de desarrollo](#comandos-de-desarrollo)
8. [Pruebas y cobertura](#pruebas-y-cobertura)
9. [Resiliencia y modo caos](#resiliencia-y-modo-caos)
10. [Personalización y Server-Driven UI](#personalización-y-server-driven-ui)
11. [Flujo de trabajo (Trunk Based Development)](#flujo-de-trabajo-trunk-based-development)
12. [Decisiones de arquitectura (ADR)](#decisiones-de-arquitectura-adr)
13. [Uso de IA](#uso-de-ia)

## Visión general

| Qué pide el reto | Cómo lo resuelve Nexo |
|------------------|------------------------|
| Onboarding y autenticación | Onboarding de 3 pasos, registro, login, recuperar contraseña y sesión persistente (Firebase Auth) |
| Cuentas, saldos y movimientos | Cuentas en Firestore, movimientos paginados y transferencias entre cuentas propias, atómicas e idempotentes |
| Personalización dinámica | Home por Server-Driven UI desde Remote Config, distinta por segmento de cliente y en tiempo real, con feature flags |
| Servicio o micro app externa | Divisas con tasas reales de ExchangeRate-API y caché stale-while-revalidate |
| Notificaciones push | FCM con deep links seguros, token por usuario y aviso con la app abierta |
| Monitoreo en producción | Crashlytics, Performance y Analytics sin datos personales, con SLOs y alertas propuestas |
| Conectividad limitada | Persistencia offline de Firestore, reintentos con backoff, caché y avisos; modo caos para demostrarlo |
| Pruebas | Tests unitarios y de widgets en cada paquete, test de reglas de arquitectura y un E2E del flujo crítico contra Firebase real |

**Demo:** el [guion de demo](docs/demo/guion-demo.md) recorre los 15 escenarios con pasos y resultado esperado.

## Arquitectura

Monorepo modular ([ADR-001](docs/adr/ADR-001-monorepo-modular.md)): un paquete por dominio con dueño propio, y una app
**shell** que los compone. Los features no dependen entre sí, y un test lo verifica en cada PR. Dentro de cada feature,
Clean Architecture: `presentation` y `data` dependen de `domain`, y los errores viajan como `Either<Failure, T>`.

Diagramas de componentes, dependencias y flujos, riesgos y escalamiento: [`docs/architecture`](docs/architecture/README.md).

## Estructura del monorepo

```text
apps/banking_app                -> shell: arranque por flavor, rutas, DI, home SDUI, personalización, push, observabilidad
packages/core                   -> red resiliente (dio + reintentos + caos), Failures, montos, almacenamiento local, Telemetry
packages/design_system          -> tokens, temas claro y oscuro, componentes accesibles, logo
packages/sdui                   -> motor Server-Driven UI: JSON → registro → widgets
packages/features/auth          -> onboarding, registro, login, sesión
packages/features/accounts      -> cuentas, movimientos, transferencias, apertura desde la plantilla
packages/features/notifications -> FCM (sin UI)
packages/features/fx_rates      -> micro app de divisas (API pública real)
firebase/                       -> reglas de Firestore, plantillas de Remote Config y de apertura
docs/                           -> arquitectura, ADRs, resiliencia, operación, demo, diseño y uso de IA
```

## Requisitos previos

| Herramienta | Versión usada | Para qué |
|-------------|---------------|----------|
| Flutter (incluye Dart) | 3.44.7 (Dart 3.12.2) | Todo |
| Android Studio y un emulador **con Google Play** | API 34 | Correr la app y recibir push |
| Xcode | 27 | iOS (deployment target 15.0) |
| JDK | 17 o superior (probado con 21) | Gradle |
| Firebase CLI | 15.32 | Solo para publicar reglas y Remote Config |
| gcloud | Cualquiera reciente | Solo para publicar la plantilla de apertura |
| FlutterFire CLI | 1.4.1 | Solo para reconfigurar Firebase |

Melos 8 viene como dependencia del workspace (`dart run melos`): no hace falta instalarlo.

## Puesta en marcha

```bash
git clone https://github.com/Denniss2C/bi-digital-banking.git
cd bi-digital-banking
make setup      # dependencias de todo el workspace y código generado
make run-dev    # con un emulador abierto
```

La configuración de Firebase de cliente está versionada (no son secretos), así que la app se conecta al proyecto
`bi-digital-banking` sin pasos extra: registra un usuario y la app le abre sus cuentas.

**Con un proyecto Firebase propio:**
1. `flutterfire configure` por flavor ([`deployment-operations.md`](docs/deployment-operations.md) §1).
2. Publica la configuración del backend:
   ```bash
   make deploy-rules     # reglas de Firestore
   make deploy-rc        # home por segmento y feature flags
   make deploy-opening   # plantilla de apertura de cuentas
   ```

## Flavors y configuración

| | dev | prod |
|-|-----|------|
| Nombre en el teléfono | Nexo Dev (con cinta DEV) | Nexo |
| Android `applicationId` | `com.dennis.banking_app.dev` | `com.dennis.banking_app` |
| iOS bundle ID | `com.dennis.bankingApp.dev` | `com.dennis.bankingApp` |
| Panel de depuración y modo caos | Sí | No |
| Remote Config | Valores nuevos en cada pull to refresh | Como mucho una vez por hora (más las actualizaciones en tiempo real) |
| Cómo correrlo | `make run-dev` | `make run-prod` |

Detalle de entornos, Firebase por flavor, CI, observabilidad y operación de contenido en
[`docs/deployment-operations.md`](docs/deployment-operations.md). Decisión en
[ADR-002](docs/adr/ADR-002-flavors-firebase.md).

## Comandos de desarrollo

`make help` los lista todos.

| Para | Comandos |
|------|----------|
| Preparar el entorno | `make setup`, `make bootstrap`, `make gen` |
| Calidad | `make analyze`, `make format`, `make format-check` |
| Pruebas | `make test`, `make coverage`, `make e2e` |
| Correr y compilar | `make run-dev`, `make run-prod`, `make build-apk-dev`, `make build-apk-prod` |
| Backend y contenido | `make rc-template`, `make deploy-rc`, `make deploy-rules`, `make deploy-opening` |
| Marca | `make brand-assets` (ícono y splash desde el logo vectorial) |

## Pruebas y cobertura

| Tipo | Dónde | Cómo correrlas |
|------|-------|----------------|
| Unitarias y de widgets | `test/` de cada paquete: blocs, repositorios, casos de uso, componentes y pantallas | `make test`; cobertura combinada con `make coverage` |
| Reglas de arquitectura | `apps/banking_app/test/architecture/` | `make test` |
| E2E del flujo crítico | `apps/banking_app/integration_test/critical_flow_test.dart` | `make e2e` en un emulador o dispositivo (`DEVICE=<id>` si hay varios) |

**E2E.** Recorre login → Inicio → Cuentas → Cuenta de Ahorros → movimientos (dos páginas de Firestore) → logout, contra
el Firebase **real** del flavor dev. Necesita un usuario de prueba:

1. Regístralo una vez desde la app (`make run-dev` → Crear cuenta), por ejemplo `e2e@nexo.test`. En iOS, el sistema
   puede llenar sola una "Contraseña segura" en el registro: verifica cuál quedó antes de copiarla.
2. Copia `apps/banking_app/e2e.env.example.json` a `apps/banking_app/e2e.env.json` (git lo ignora) y completa su
   correo y su contraseña.
3. Corre `make e2e`.

- **Qué escribe:** solo lee datos. Lo único que escribe es la apertura de cuentas en el primer login del usuario y el
  token de push, que se borra al cerrar sesión.
- **Qué verifica:** la estructura (dos cuentas y los movimientos hasta el depósito de apertura), no saldos exactos.
- **Efecto en el dispositivo:** usa la app dev instalada y termina con la sesión cerrada.
- **Fuera del CI:** necesita un dispositivo y credenciales. El paso siguiente sería correrlo contra el Emulator Suite de
  Firebase, con datos efímeros.

## Resiliencia y modo caos

- **Cada pantalla tiene sus estados:** carga, datos, vacío, error con reintento y offline con los últimos datos.
- **Reintentos:** las llamadas HTTP pasan por un `RetryInterceptor` con backoff exponencial y jitter (3 intentos, solo
  errores transitorios).
- **Sin conexión:** Firestore trabaja con su caché offline y muestra un aviso; la API de divisas usa caché
  stale-while-revalidate.
- **Modo caos (solo dev):** el panel de depuración inyecta latencia, fallos o falta de red, y desconecta Firestore,
  para demostrar todo lo anterior.

Detalle y escenarios en [`docs/resilience.md`](docs/resilience.md).

## Personalización y Server-Driven UI

- **La home es un JSON** (`home_layout` en Remote Config) que el motor `sdui` convierte en widgets. Cada componente lo
  aporta un feature: saldo, movimientos, divisas, promociones y atajos.
- **Por segmento:** el segmento del cliente viaja a Remote Config como *custom signal*, y cada segmento recibe su
  layout. Los cambios publicados llegan en segundos, sin reiniciar.
- **A prueba de errores:** un tipo desconocido se omite (forward compatibility); un JSON inválido cae al layout
  embebido en la app; las acciones solo abren pantallas de la app.
- **Feature flags:** `feature_transfers_enabled` y `feature_fx_enabled` apagan funciones sin publicar la app.
- **Cambiar la home:** edita `firebase/remote-config/*.json` y corre `make deploy-rc`, o hazlo desde la consola.

Contrato y catálogo en el [README de `sdui`](packages/sdui/README.md); decisiones en
[ADR-004](docs/adr/ADR-004-sdui-engine.md) y [ADR-005](docs/adr/ADR-005-remote-config-personalization.md).

## Flujo de trabajo (Trunk Based Development)

- **`main` está protegida:** solo entra por PR, con historial lineal y merge por rebase. El check obligatorio es
  "Analyze, format and test".
- **Ramas cortas** (horas) con prefijo (`feat/`, `fix/`, `docs/`, `test/`, `chore/`, `ci/`) y **Conventional
  Commits**.
- **Cada PR:**
  - usa la [plantilla](.github/pull_request_template.md);
  - actualiza el [CHANGELOG](CHANGELOG.md) (Keep a Changelog);
  - pasa `make analyze && make test`.
- **Dueños por paquete** en [`CODEOWNERS`](.github/CODEOWNERS).
- **Lo no terminado entra detrás de un feature flag.**

## Decisiones de arquitectura (ADR)

| ADR | Decisión |
|-----|----------|
| [001](docs/adr/ADR-001-monorepo-modular.md) | Monorepo modular con Melos y pub workspaces |
| [002](docs/adr/ADR-002-flavors-firebase.md) | Entornos dev/prod con flavors sobre un único proyecto Firebase |
| [003](docs/adr/ADR-003-accounts-firestore.md) | Datos bancarios en Firestore con escrituras desde el cliente (plan Spark) |
| [004](docs/adr/ADR-004-sdui-engine.md) | Server-Driven UI con un catálogo de componentes de negocio |
| [005](docs/adr/ADR-005-remote-config-personalization.md) | Personalización con Remote Config y el segmento como custom signal |
| [006](docs/adr/ADR-006-fx-rates-provider.md) | Divisas con una API pública sin clave y caché stale-while-revalidate |
| [007](docs/adr/ADR-007-opening-template.md) | Plantilla de apertura de cuentas en Firestore, publicada con `gcloud` |

## Uso de IA

El proyecto se desarrolló con Claude Code. [`docs/ai/AI_USAGE.md`](docs/ai/AI_USAGE.md) registra, paso por paso, qué se
pidió, qué se aceptó, **qué hizo mal la IA y cómo se corrigió**, y su impacto en productividad, calidad, documentación
y pruebas. Los prompts están en [`docs/ai/prompts/`](docs/ai/prompts/).
