# banking_app

La app **Nexo**: el shell que compone los paquetes del monorepo y lo único que se instala. No tiene reglas de
negocio propias. Arranca Firebase según el flavor, arma la inyección de dependencias y las rutas, y conecta los
features, que nunca se importan entre sí. Dueño: `@team-platform`.

Qué conecta y por qué: [dependencias](../../docs/architecture/dependencies.md#qué-compone-el-shell) y
[componentes](../../docs/architecture/components.md). Flavors y Firebase:
[`deployment-operations.md`](../../docs/deployment-operations.md) §1.

## Estructura

```text
lib/
  main_dev.dart, main_prod.dart    entry point de cada flavor (main.dart reexporta el de dev)
  bootstrap.dart                   Firebase del flavor, errores a Crashlytics, DI y runApp
  firebase_options_<flavor>.dart   opciones de Firebase (generadas por flutterfire)
  di/                              get_it + injectable; el entorno de injectable es el flavor
  app/
    config/                        AppConfig: flavor, nombre visible y herramientas de debug
    router/                        go_router: rutas, redirect según la sesión y rutas apagadas por flag
    shell/                         barra inferior: Inicio, Cuentas, Divisas y Perfil
    home/                          home por SDUI: registro de componentes y layout por defecto embebido
    personalization/               Remote Config: layout por segmento y feature flags, en tiempo real
    session_effects.dart           al iniciar sesión, abre las cuentas del cliente (auth → accounts)
    push/                          PushCoordinator: token por sesión y rutas de las notificaciones
    observability/                 FirebaseTelemetry: Crashlytics, Performance y Analytics
    debug/                         panel de depuración (solo dev): caos HTTP, Firestore sin red, segmento, push,
                                   observabilidad y Remote Config
    pages/                         splash, perfil y "función no disponible"
  l10n/                            textos del shell en español e inglés
tool/                              ícono y splash, plantillas de Remote Config y de apertura, flavors de iOS
integration_test/                  E2E del flujo crítico
test/                              tests del shell, incluido el de reglas de dependencias (test/architecture/)
```

## Ejecutar y probar

Desde la raíz del repo ([README principal](../../README.md)):

```bash
make run-dev    # flavor dev, con el panel de depuración
make test       # tests de todos los paquetes
make e2e        # flujo crítico contra el Firebase de dev (necesita e2e.env.json)
```

## Código generado

`lib/di/injection.config.dart` (injectable) y `lib/l10n/gen/` se versionan. `make gen` los regenera, y CI falla si
quedaron desactualizados.
