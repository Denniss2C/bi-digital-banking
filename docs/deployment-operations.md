# Despliegue y operación

> Estado: estructura inicial. Las secciones marcadas _Pendiente_ se completan en el paso que las implementa.

## 1. Entornos (flavors)

| Flavor | Android (applicationId) | iOS (bundle ID) | Nombre | Entry point | Herramientas de debug / Chaos |
|--------|-------------------------|-----------------|--------|-------------|-------------------------------|
| `dev`  | `com.dennis.banking_app.dev` | `com.dennis.bankingApp.dev` | Nexo Dev | `lib/main_dev.dart` | ✅ |
| `prod` | `com.dennis.banking_app` | `com.dennis.bankingApp` | Nexo | `lib/main_prod.dart` | ❌ |

- Los dos flavors usan **el mismo proyecto Firebase** (`bi-digital-banking`) con **una app registrada por flavor**. La decisión y sus trade-offs están en [ADR-002](adr/ADR-002-flavors-firebase.md).
- iOS no admite `_` en el bundle ID; por eso el de iOS es `com.dennis.bankingApp`.
- `flutter run` sin argumentos arranca en **dev** (`default-flavor: dev` en el `pubspec.yaml` y `lib/main.dart`, que reexporta `main_dev.dart`). Así una ejecución sin argumentos nunca apunta a producción.

### Cómo ejecutar

```bash
make run-dev            # flutter run --flavor dev -t lib/main_dev.dart
make run-prod           # flutter run --flavor prod -t lib/main_prod.dart
make build-apk-dev      # APK release del flavor dev
make build-apk-prod     # APK release del flavor prod
```

En VS Code, las configuraciones `banking_app (dev)` y `banking_app (prod)` de `.vscode/launch.json` hacen lo mismo.

### Dónde vive la configuración de cada flavor

| Capa | Archivo | Qué define |
|------|---------|------------|
| Dart | `lib/app/config/app_config.dart` | `Flavor`, nombre de la app y `enableDebugTools` (solo dev) |
| Dart | `lib/main_<flavor>.dart` → `lib/bootstrap.dart` | Inicializa Firebase con las opciones del flavor y arranca la app |
| Dart | `lib/firebase_options_<flavor>.dart` | Opciones de Firebase del flavor (generado por flutterfire) |
| Android | `android/app/build.gradle.kts` | `productFlavors` `dev` (sufijo `.dev`) y `prod`, nombre vía `manifestPlaceholders` |
| Android | `android/app/src/<flavor>/google-services.json` | Configuración nativa de Firebase del flavor |
| iOS | `ios/Flutter/<flavor>.xcconfig` | `APP_FLAVOR`, `APP_DISPLAY_NAME` y `PRODUCT_BUNDLE_IDENTIFIER` |
| iOS | `ios/Flutter/<Modo>-<flavor>.xcconfig` | Une la configuración base de Flutter (`Debug` o `Release`) con los valores del flavor |
| iOS | `ios/flavors/<flavor>/GoogleService-Info.plist` | Configuración nativa de Firebase del flavor |
| iOS | Schemes `dev` y `prod` | Usan las configuraciones `Debug-<flavor>`, `Profile-<flavor>` y `Release-<flavor>` |

El proyecto de Xcode se migró con [`tool/setup_ios_flavors.rb`](../apps/banking_app/tool/setup_ios_flavors.rb), que documenta cada cambio del `project.pbxproj`.

### Firebase por flavor

Se generan con FlutterFire CLI desde `apps/banking_app`, un comando por flavor. La primera vez, el
comando de dev registra las apps `com.dennis.banking_app.dev` (Android) y `com.dennis.bankingApp.dev`
(iOS) en el proyecto. El de prod reutiliza las apps que ya existen.

```bash
cd apps/banking_app

flutterfire configure \
  --project=bi-digital-banking \
  --platforms=android,ios \
  --out=lib/firebase_options_dev.dart \
  --android-package-name=com.dennis.banking_app.dev \
  --android-out=android/app/src/dev/google-services.json \
  --ios-bundle-id=com.dennis.bankingApp.dev \
  --ios-build-config=Debug-dev \
  --ios-out=ios/flavors/dev/GoogleService-Info.plist \
  --yes

flutterfire configure \
  --project=bi-digital-banking \
  --platforms=android,ios \
  --out=lib/firebase_options_prod.dart \
  --android-package-name=com.dennis.banking_app \
  --android-out=android/app/src/prod/google-services.json \
  --ios-bundle-id=com.dennis.bankingApp \
  --ios-build-config=Debug-prod \
  --ios-out=ios/flavors/prod/GoogleService-Info.plist \
  --yes
```

**Cómo llega el plist a la app en iOS.** Un build phase propio del target Runner
(`Copy GoogleService-Info.plist for flavor`) copia `ios/flavors/$(APP_FLAVOR)/GoogleService-Info.plist`
al bundle en **todas** las configuraciones del flavor (Debug, Profile y Release).

No usamos el script que flutterfire agrega con `--ios-build-config`, por dos motivos:
- ese script busca el plist por el nombre exacto de la configuración y, si no lo encuentra (por ejemplo,
  `Release-dev`), **termina sin error y sin copiar nada**;
- además necesita el ejecutable `flutterfire` en el PATH de Xcode.

Si flutterfire vuelve a agregar su build phase `FlutterFire: "flutterfire bundle-service-file"`, hay que eliminarla.

**Dependencias nativas en iOS.** Todos los plugins se resuelven con Swift Package Manager; el proyecto
no usa CocoaPods ni tiene `Podfile`. Las versiones quedan fijadas en los `Package.resolved` del workspace.

### Problema conocido: `flutter build ios --simulator` con Xcode 27

Con Flutter 3.44.7 y Xcode 27, `flutter build ios --simulator` falla en la fase
`Run Prepare Flutter Framework Script` con `Exited with status code 255`.

La causa: el build para simulador genérico incluye `arm64` y `x86_64`, y Flutter verifica el framework
con `lipo <binario> -verify_arch arm64 x86_64`. El `lipo` de Xcode 27 solo acepta una arquitectura en
ese comando (`-verify_arch requires exactly one input file`). No tiene relación con los flavors.

Alternativas que sí funcionan, porque compilan una sola arquitectura:
- `flutter run` sobre un simulador o dispositivo concreto (por ejemplo, `make run-dev`);
- un build de dispositivo sin firmar: `flutter build ios --no-codesign --flavor <flavor> -t lib/main_<flavor>.dart`.

### Aviso conocido: plugins con Kotlin Gradle Plugin en Android

El build de Android termina bien, pero Flutter 3.44 avisa que `firebase_auth`, `firebase_core` y
`firebase_remote_config` aplican el Kotlin Gradle Plugin (KGP) y que **una versión futura de Flutter dejará de
compilarlos** hasta que migren a "Built-in
Kotlin". El aviso viene de los plugins: ya usamos sus últimas versiones (`flutter pub outdated`), así que no hay nada
que corregir en el proyecto. Hay que revisarlo antes de actualizar Flutter.

### Errores en `build/` de la raíz en el IDE

Resolver dependencias en la raíz (`make bootstrap`) hace que Swift Package Manager copie el código de los plugins,
con sus tests y ejemplos, en `build/ios` y `build/macos`. Esa carpeta está ignorada por git y el
`analysis_options.yaml` de la raíz la excluye del análisis. Si un IDE igual muestra errores ahí, se puede borrar sin
riesgo: se regenera sola.

## 2. Configuración y secretos

- No hay secretos en el repositorio. Las opciones de cliente de Firebase (`firebase_options_*.dart`)
  **no son secretos**: identifican la app ante Firebase. La protección real viene de:
  - Restricciones de API key en Google Cloud Console (por package name + SHA-1 en Android y por bundle ID en iOS).
  - Reglas de seguridad de Firestore.
  - _Planificado:_ App Check.
- Los valores que cambian sin publicar versión (feature flags, contenido SDUI) viven en Remote Config.

## 2.1 Reglas de seguridad de Firestore

Versionadas en `firebase/firestore.rules` (configuración en `firebase.json` y `.firebaserc` de la raíz). Se despliegan
con el CLI de Firebase:

```bash
make deploy-rules   # firebase deploy --only firestore:rules --project bi-digital-banking
```

El CLI compila las reglas antes de publicarlas: si tienen un error de sintaxis, no se cambia nada. La consola guarda el
historial de versiones, así que se pueden revertir. Contenido y trade-offs en [ADR-003](adr/ADR-003-accounts-firestore.md).

## 3. Integración continua

Workflow [`.github/workflows/ci.yml`](../.github/workflows/ci.yml): un job (`Analyze, format and test`) en cada
push a `main` y en cada PR hacia `main`.

| Paso | Comando | Falla si… |
|------|---------|-----------|
| Flutter 3.44.7 (fijo, con caché) | `subosito/flutter-action@v2` | — |
| Bootstrap | `dart pub get` + `make bootstrap` | las dependencias no resuelven |
| Formato | `make format-check` | algún archivo no está formateado |
| Análisis | `make analyze` | hay errores, warnings o *infos* (`--fatal-infos`) |
| Tests | `make test` | falla algún test de cualquier paquete |
| Código generado | `make gen` + `git diff --exit-code` | el código de injectable o de l10n versionado está desactualizado |

- CI usa **los mismos targets del Makefile** que el desarrollo local, así ambos no se desincronizan.
- Melos se ejecuta como dependencia de desarrollo de la raíz (`dart run melos`), con la versión del lockfile y sin
  instalación global.
- **Concurrencia:** un push nuevo a la misma rama cancela la ejecución en curso. Los permisos son de solo lectura.
- **Protección de `main`:** este check es obligatorio para mergear, junto con PR obligatorio, historial lineal y merge
  solo por rebase.
- No requiere secretos: las opciones de cliente de Firebase no lo son (ver §2).
- **Duración** de la primera ejecución, sin caché: 6 min 46 s. Por paso: instalar Flutter 68 s, analizar 36 s, tests
  73 s y verificar el código generado 197 s. Este último es el más lento porque build_runner compila sus builders en
  los 6 paquetes que dependen de él. _Optimización posible:_ limitarlo a los paquetes que tienen anotaciones.

## 4. Build y distribución

```bash
make build-apk-dev    # APK release con flavor dev
make build-apk-prod   # APK release con flavor prod
```

_Pendiente:_ firma de release, distribución (Firebase App Distribution), versionado.

### Ícono de la app y splash

Salen del logo vectorial `NexoLogo` de `design_system`: `make brand-assets` dibuja con ese painter y escribe los PNG en
los proyectos nativos (`apps/banking_app/tool/brand_assets_test.dart`; es un test solo para tener el motor de Flutter, y
`make test` no lo corre). Hay que correrlo solo si cambia el logo; la salida es determinista y los PNG se versionan.

| Plataforma | Ícono | Splash |
|------------|-------|--------|
| Android 8+ | Ícono adaptativo (`mipmap-anydpi-v26/ic_launcher.xml`): fondo navy (`values/colors.xml`), la marca como primer plano y una silueta para los íconos temáticos de Android 13 | Android 12+ dibuja su propio splash: el ícono sobre navy (`values-v31` y `values-night-v31`) |
| Android 7 | `mipmap-*/ic_launcher.png` | `launch_background.xml` (iguales en `drawable/` y `drawable-v21/`): navy con la marca al centro |
| iOS | Un solo PNG de 1024 px (Xcode genera los demás tamaños), opaco porque el App Store rechaza íconos con canal alfa | `LaunchScreen.storyboard`: navy con la marca al centro |

- **Sin saltos al abrir:** la primera pantalla de Flutter (`SplashPage`) repite el splash nativo, con el mismo navy y la
  marca a 88 dp en el centro, mientras se restaura la sesión.
- **Mismo ícono en los dos flavors:** dev y prod se distinguen por el nombre ("Nexo Dev" / "Nexo") y la cinta DEV.
- **Para verlos en un dispositivo,** desinstala la app y vuelve a instalarla: Android e iOS guardan el ícono y el
  splash en caché.
- **`drawable-v21/launch_background.xml` no se borró,** aunque con `minSdk` 24 basta un archivo: borrarlo rompe la
  fusión incremental de recursos de Gradle en builds existentes (`resource drawable/launch_background not found`). Si
  aparece ese error, `flutter clean` lo resuelve.
- **Sin generadores de terceros:** `flutter_launcher_icons` 0.14 choca con Melos 8 (`cli_util`), y sus versiones viejas
  bajaban `xml` y volvían a CocoaPods. Por eso el generador es propio y los XML de Android y el storyboard están escritos
  a mano.

## 5. Versionado y releases

- SemVer en `apps/banking_app/pubspec.yaml` (`version: X.Y.Z+build`).
- Cada PR actualiza `CHANGELOG.md` en `[Unreleased]`; al hacer release se mueve a una versión con fecha y se crea el tag `vX.Y.Z`.

## 6. Observabilidad

Todo pasa por la interfaz `Telemetry` de `core`, que el shell implementa con Firebase (`FirebaseTelemetry`). Los
features reportan sin depender de Firebase, y en los tests usan `RecordingTelemetry`.

### Qué se recoge

| Herramienta | Qué | Dónde |
|-------------|-----|-------|
| Crashlytics | Errores no capturados (Flutter y plataforma), como fatales | `bootstrap.dart` |
| Crashlytics | Errores inesperados no fatales: un componente SDUI que falla, la apertura de cuentas con error de servidor | home, `SessionEffects` |
| Performance | Arranque de la app y pantallas lentas o congeladas (automático) | SDK |
| Performance | Cada llamada HTTP: duración, código y tamaño, por intento | `PerformanceHttpInterceptor` (dio) |
| Performance | Traza `transfer_submit`: duración de la transferencia, con el atributo `result` | `TransferPage` |
| Analytics | Pantallas y eventos de negocio y de UX (tabla siguiente) | shell y features |

| Evento | Parámetros | Para qué |
|--------|------------|----------|
| `screen_view` | `screen_name` (patrón de ruta, p. ej. `/accounts/:accountId`) | Navegación y embudos |
| `login` | — | Inicios de sesión reales (una sesión restaurada no cuenta) |
| `transfer_completed` | — | Conversión del embudo de transferencias |
| `transfer_failed` | `reason` (regla rota o tipo de fallo) | Por qué fallan las transferencias |
| `home_layout` | `source` (`remote`/`fallback`), `issues` | Salud de Remote Config y del SDUI |
| `sdui_component_failed` | `type` | Componentes que fallan en producción |
| `sdui_route_ignored` | `route` | Layouts con rutas que la app no tiene |
| `feature_unavailable` | `route` | Usuarios que intentan usar una función apagada |
| `push_opened` | `route` | Qué notificaciones se abren |

**Privacidad:**
- el usuario es el uid de Firebase (seudónimo);
- nunca se envían nombres, correos, números de cuenta ni montos;
- las rutas van por patrón, sin ids;
- estar sin conexión es un evento esperado, no un error: no llena Crashlytics de ruido.

### SLOs propuestos

| Indicador | Objetivo | Fuente |
|-----------|----------|--------|
| Usuarios sin crashes | ≥ 99.5 % en 7 días | Crashlytics |
| Éxito técnico de transferencias | ≥ 99 % (`transfer_failed` con `reason` `network`, `server` o `auth` frente al total; las reglas de negocio no cuentan) | Analytics |
| Duración de `transfer_submit` | p95 < 3 s | Performance |
| Respuestas 2xx de la API de divisas | ≥ 98 % | Performance (HTTP) |
| Home con layout remoto | ≥ 95 % de `home_layout` con `source=remote` | Analytics |

### Alertas propuestas

Se configuran en la consola; este repo no las automatiza.

- **Crashlytics:** alerta de velocidad (un issue que afecta a más del 1 % de los usuarios en una hora), regresiones e
  issues fatales nuevos, enviadas por correo o Slack.
- **Performance:** umbral en `transfer_submit` (p95 > 3 s) y en la tasa de éxito de la API de divisas (< 98 %).
- **Analytics** (con export a BigQuery): `home_layout` con `fallback` por encima del 5 % en una hora (señal de un
  JSON roto recién publicado) y picos de `feature_unavailable`.

### Cómo detectar problemas de UX

- **Embudo** `screen_view /accounts/transfer` → `transfer_completed`: dónde se cae la gente.
- **`transfer_failed` por `reason`:** muchos `insufficientFunds` sugieren mostrar mejor el saldo disponible; muchos
  `network`, problemas de conectividad.
- **`feature_unavailable` y `sdui_route_ignored`:** una configuración remota que confunde o lleva a callejones sin
  salida.
- **Pantallas lentas o congeladas** (Performance) y `home_layout` con `issues` > 0 después de publicar un layout.

### Verificarlo en la demo

- **Crashlytics:** en **Perfil → Panel de depuración → Observabilidad**, "Enviar error de prueba" aparece en
  Crashlytics del proyecto dev en minutos. "Forzar cierre" aparece al volver a abrir la app.
- **Analytics en tiempo real:** `adb shell setprop debug.firebase.analytics.app com.dennis.banking_app.dev`; los
  eventos se ven en **Analytics → DebugView**.
- **Performance** procesa los datos con algunas horas de retraso: sirve para tendencias, no para la demo en vivo.
- **Builds de Android:** el plugin de Gradle de Crashlytics (3.0.8) inyecta el build ID que necesita el SDK.

## 7. Operación de contenido (sin publicar versión)

La home y los feature flags vienen de **Remote Config**. La decisión está en
[ADR-005](adr/ADR-005-remote-config-personalization.md) y el formato de los layouts, en el
[README de `sdui`](../packages/sdui/README.md).

| Parámetro | Tipo | Para qué |
|-----------|------|----------|
| `home_layout` | JSON | Layout SDUI de la home. Valor por defecto, más uno por segmento (`segment_saver`, `segment_traveler`). |
| `feature_transfers_enabled` | Booleano | Apaga las transferencias: oculta el botón, bloquea la ruta y los atajos explican que no está disponible. |
| `feature_fx_enabled` | Booleano | Divisas (se aplica en `feat/fx-rates`). |
| `feature_ai_assistant_enabled` | Booleano | Asistente con IA (bonus). |

**Segmentos.** La app envía el segmento del cliente (`users/{uid}.segment`, `new_user` al abrir la cuenta) como
*custom signal* `segment`. Las condiciones de la plantilla eligen el layout en el servidor; un segmento sin condición
recibe el valor por defecto. Para probar otro segmento, cambia `segment` del usuario en la consola de Firestore: la app
pide el layout nuevo en el momento.

### Cambiar la home

- **En vivo, desde la consola** (demo): Remote Config → `home_layout` → editar el JSON → Publicar. Las apps abiertas
  reciben el cambio en segundos (actualizaciones en tiempo real), sin reiniciar. Después, trae el cambio al repo:
  `firebase remoteconfig:get --project bi-digital-banking -o firebase/remoteconfig.template.json` (y actualiza los
  archivos de `firebase/remote-config/`).
- **Desde el repo** (lo normal): edita `firebase/remote-config/home_layout.<segmento>.json`, corre `make rc-template`
  y abre un PR. Los tests verifican que la plantilla esté al día, que cada layout sea válido y que sus rutas existan en
  la app. Al mergear, `make deploy-rc` la publica.

### Si algo sale mal

- **Un JSON roto o de una versión de esquema más nueva** no rompe la app: se usa el layout embebido, y un componente
  inválido se omite sin afectar al resto.
- **Revertir:** la consola de Remote Config guarda cada versión publicada (Historial de cambios → Revertir).
- **Sin conexión**, la app usa los últimos valores que activó, o los embebidos si nunca descargó ninguno.
- **Cuotas.** En prod, la app pide valores como mucho una vez por hora; en dev, en cada pull to refresh. Las
  actualizaciones en tiempo real llegan en ambos casos. Cambiar de segmento pide los valores en el momento.

### Plantilla de apertura de cuentas

Las cuentas y los primeros movimientos de cada cliente nuevo salen de `templates/opening` en Firestore, no del código
de la app ([ADR-007](adr/ADR-007-opening-template.md)). La fuente es `firebase/opening-template.json`.

- **Requisito, una vez por máquina:** `gcloud`, con una cuenta del proyecto.
  ```bash
  brew install --cask google-cloud-sdk
  gcloud auth login
  ```
- **Publicarla:** `make deploy-opening`. Valida el archivo con el mismo código que usa la app y lo escribe en
  Firestore. `dart run tool/opening_template.dart --dry-run` (desde `apps/banking_app`) muestra la petición sin
  enviarla.
- **Proyecto nuevo:** hay que publicarla antes del primer cliente. Sin plantilla, la apertura no escribe nada,
  Crashlytics registra el error (`opening data`) y el próximo inicio de sesión lo reintenta. Mientras tanto, el
  cliente ve "Estamos preparando tus cuentas".
- **Cambiarla:** edita el JSON y abre un PR (los tests verifican que sea válido y que sobreviva el viaje a Firestore);
  al mergear, `make deploy-opening`. También se puede editar en la consola, pero entonces el repo queda desactualizado.
- **Solo afecta a los clientes nuevos:** quien ya abrió sus cuentas conserva su historial.

### Enviar notificaciones push

La demo es en **Android**: iOS necesita una clave APNs en Firebase y la capacidad de Push en Xcode, que este proyecto
no tiene configuradas. Sin eso la app funciona en iOS, pero no recibe notificaciones.

1. Con `make run-dev`, inicia sesión y acepta el permiso. La app guarda el token en `users/{uid}.fcmTokens`.
2. En **Perfil → Panel de depuración → Notificaciones push**, toca **Copiar token**.
3. En la consola de Firebase: **Messaging → Nueva campaña → Notificaciones**, escribe el título y el texto, y toca
   **Enviar mensaje de prueba** con el token copiado.
4. Opcional: en **Opciones adicionales → Datos personalizados**, agrega `route` = `/fx` (o `/accounts`,
   `/accounts/transfer`).

| Estado de la app | Qué pasa |
|------------------|----------|
| Abierta | Aparece un aviso con el título y el texto; **Ver** abre `route` |
| En segundo plano o cerrada | El sistema muestra la notificación; al tocarla, la app abre `route` |
| `route` desconocida o externa | Solo se abre la app: el shell nunca navega fuera de sus pantallas |

Para notificar desde un backend, los tokens de cada usuario están en `users/{uid}.fcmTokens`. Una Cloud Function al
crear un movimiento necesitaría el plan Blaze.

## 8. Runbook de incidentes

_Pendiente:_ qué revisar ante caídas de la API de tipo de cambio, errores de Firebase o crashes masivos.
