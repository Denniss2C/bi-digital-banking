# Despliegue y operación

Cómo se configura, compila, publica y opera la app: entornos, secretos, CI, firma y distribución, versiones,
observabilidad, cambios sin publicar versión y qué hacer ante un incidente.

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
con sus tests y ejemplos, en `build/` (por ejemplo, `build/ios/SourcePackages`). Esa carpeta está ignorada por git
y el `analysis_options.yaml` de la raíz la excluye del análisis. Si un IDE igual muestra errores ahí, se puede borrar
sin riesgo: se regenera sola.

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
  73 s y verificar el código generado 197 s. Este último era el más lento porque build_runner compilaba sus builders
  en los 6 paquetes que lo declaraban. Desde el 2026-10-05 solo lo declara el shell, el único paquete con anotaciones
  de injectable, así que corre en uno solo (en local, `make gen` completo tarda 43 s).

## 4. Build y distribución

```bash
make build-apk-dev    # APK release con flavor dev
make build-apk-prod   # APK release con flavor prod
```

Solo Android e iOS: las carpetas de web y escritorio que crea `flutter create` se quitaron porque no tienen flavors ni
Firebase configurado. Si alguna vez hacen falta, `flutter create --platforms=<plataforma> .` las vuelve a generar.

### Firma

Los builds de release se firman con la **clave de debug** (`android/app/build.gradle.kts`): los APK de la demo se
instalan a mano y nunca se suben a una tienda. Para publicar en Google Play, según la
[guía de Flutter](https://docs.flutter.dev/deployment/android):

1. Crear una clave de subida, una sola vez y fuera del repo:
   ```bash
   keytool -genkey -v -keystore ~/nexo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Crear `apps/banking_app/android/key.properties`. Git ya lo ignora, igual que los `*.jks` y `*.keystore`:
   ```properties
   storePassword=<contraseña del keystore>
   keyPassword=<contraseña de la clave>
   keyAlias=upload
   storeFile=/Users/<usuario>/nexo-upload.jks
   ```
3. Leerlo en `build.gradle.kts` (cambio propuesto, no aplicado en este repo):
   ```kotlin
   import java.io.FileInputStream
   import java.util.Properties

   val keystorePropertiesFile = rootProject.file("key.properties")
   val keystoreProperties = Properties()
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           if (keystorePropertiesFile.exists()) {
               create("release") {
                   keyAlias = keystoreProperties["keyAlias"] as String
                   keyPassword = keystoreProperties["keyPassword"] as String
                   storeFile = file(keystoreProperties["storeFile"] as String)
                   storePassword = keystoreProperties["storePassword"] as String
               }
           }
       }
       buildTypes {
           release {
               // Without key.properties (another machine, CI without secrets)
               // it keeps signing with the debug key.
               signingConfig = signingConfigs.findByName("release")
                   ?: signingConfigs.getByName("debug")
           }
       }
   }
   ```
4. Activar **Play App Signing**: Google guarda la clave que firma la app y el equipo conserva solo la de subida, que
   se puede reemplazar si se pierde.
5. Generar el bundle: `flutter build appbundle --flavor prod -t lib/main_prod.dart`.

- **En CI**, el keystore (en base64) y las contraseñas irían como secretos del repositorio: el job los escribe en disco
  antes del build. Hoy CI no compila builds de release.
- **SHA-1:** si se restringe la API key por SHA-1 (§2), hay que agregar el de la clave de subida y el de Play App
  Signing.
- **iOS** necesita una cuenta de Apple Developer: el equipo de firma y los perfiles de cada bundle ID se configuran en
  Xcode, y `flutter build ipa --flavor prod -t lib/main_prod.dart` genera el archivo para TestFlight. El proyecto no
  tiene equipo configurado, por eso iOS se verifica con builds sin firmar (§1).

### Distribución

No está automatizada: en la demo, el APK se instala directamente. La propuesta:

| Etapa | Canal | Flavor |
|-------|-------|--------|
| QA interno | Firebase App Distribution, con grupos de testers | dev |
| Piloto | Google Play (pruebas interna y cerrada) y TestFlight | prod |
| Producción | Google Play con lanzamiento progresivo (1 % → 10 % → 50 % → 100 %), que se pausa si Crashlytics alerta (§6), y App Store con publicación por fases | prod |

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

- **SemVer** en `apps/banking_app/pubspec.yaml` (`version: X.Y.Z+build`). `X.Y.Z` es el nombre de la versión
  (`versionName` en Android, `CFBundleShortVersionString` en iOS) y `build`, el número de compilación (`versionCode`,
  `CFBundleVersion`). En Android, el flavor dev agrega `-dev` al nombre.
- Cada subida a una tienda necesita un `build` mayor que el anterior; en CI se puede pasar con `--build-number`.
- **Lo que se entrega es la versión de la app.** Los paquetes de `packages/` no se publican por separado: se quedan en
  `0.0.1` y sus `CHANGELOG.md` resumen qué traen (ver ADR-001).
- Cada PR actualiza `CHANGELOG.md` en `[Unreleased]`. Para publicar una versión:
  1. Un PR `chore/release-vX.Y.Z` mueve `[Unreleased]` a `[X.Y.Z] - AAAA-MM-DD` y, si hace falta, sube `version`.
  2. Después del merge, sobre `main`: `git tag -a vX.Y.Z -m "vX.Y.Z"`, `git push origin vX.Y.Z` y
     `gh release create vX.Y.Z` con las notas de esa versión.
- **Sin ramas de release** (Trunk Based Development): un parche también sale de `main`, con un PR `fix/...` y su propia
  versión.

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
| `feature_fx_enabled` | Booleano | Apaga Divisas: la pestaña dice que no está disponible, la home oculta el widget de tasas y los atajos a `/fx` lo explican. |
| `feature_ai_assistant_enabled` | Booleano | Reservado para el asistente con IA (bonus, no implementado): hoy no cambia nada. |

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

Ante cualquier incidente, el orden es el mismo:

1. **Medir el alcance** con las herramientas de §6: Crashlytics (issues y usuarios afectados, por versión), Analytics
   en tiempo real, Performance (llamadas HTTP) y el [estado de Firebase](https://status.firebase.google.com).
2. **Mitigar sin publicar versión** con lo que permite §7: apagar un feature flag, publicar otro layout o revertir una
   versión de Remote Config o de las reglas.
3. **Corregir** con una rama `fix/...`, un test que reproduzca la falla, el PR y una versión de parche (§5).
4. **Cerrar** anotando la causa, el impacto y las acciones en el PR del arreglo.

### La API de tipo de cambio no responde o está lenta

- **Señales:** en Performance baja la tasa de respuestas 2xx de `open.er-api.com` (SLO: 98 %) o sube su duración. Los
  clientes ven "No pudimos actualizar · mostrando las últimas tasas guardadas".
- **Qué hace la app sola:**
  - reintenta dos veces los errores transitorios, con backoff (`RetryInterceptor`);
  - si igual falla, muestra las últimas tasas guardadas con su antigüedad ("Actualizado hace 3 horas"), y sin caché, un
    error con Reintentar;
  - con tasas guardadas, solo vuelve a pedirlas cuando el proveedor ya publicó otras y pasó al menos una hora, o
    cuando el cliente actualiza a mano. Así no satura la API cuando vuelve.
- **Qué hacer:**
  - confirmar el estado de [ExchangeRate-API](https://www.exchangerate-api.com);
  - si la caída se alarga, apagar `feature_fx_enabled`: Divisas queda como no disponible y la home oculta el widget;
  - si el proveedor cambió el formato de la respuesta (`ServerFailure` "Invalid rates"), el arreglo va en el parser de
    `fx_rates`, con su test.
- **Reproducirlo:** en dev, el panel de depuración inyecta latencia, fallos 503 o "sin red"
  ([`resilience.md`](resilience.md) §6).

### Firestore falla o se queda sin cuota

- **Señales:** errores al cargar cuentas o movimientos, el aviso "Sin conexión · mostrando tus últimos datos
  guardados" en clientes que tienen red, o más `transfer_failed` con `reason` `network` o `server`.
- **Qué hace la app sola:** muestra saldos y movimientos desde la caché offline de Firestore, con ese aviso. Las
  transferencias necesitan conexión: fallan con un mensaje claro y, como son idempotentes (`transferId`), reintentarlas
  nunca cobra dos veces.
- **Qué hacer:**
  - revisar el estado de Firebase y el uso del proyecto (Firestore → Uso). El plan Spark tiene una cuota diaria de
    50 000 lecturas y 20 000 escrituras: al agotarse, Firestore responde `resource-exhausted` hasta que se reinicia, a
    la medianoche del Pacífico. La solución de fondo es pasar a Blaze;
  - mientras tanto, apagar `feature_transfers_enabled` evita que los clientes intenten transferencias que van a fallar.

### Errores de permisos después de cambiar las reglas

- **Señales:** justo después de `make deploy-rules`, más errores al cargar cuentas o más `transfer_failed` con
  `reason` `auth`.
- **Qué hacer:** revertir desde la consola (Firestore → Reglas → historial) o con `git revert` del cambio y
  `make deploy-rules`.
- **Prevención:** las reglas aún no tienen tests automáticos. El siguiente paso es probarlas con el emulador de
  Firestore ([riesgos](architecture/risks-and-scaling.md)).

### No se puede iniciar sesión

- **Señales:** caen los eventos `login`, o los clientes ven "Demasiados intentos" (Firebase bloquea por un rato los
  dispositivos con muchos intentos fallidos).
- **Qué hace la app sola:** quien ya había iniciado sesión entra directo, porque Firebase restaura la sesión guardada.
- **Qué hacer:** revisar el estado de Firebase Authentication y, en la consola (Authentication → Usuarios), descartar
  un abuso, como muchos registros desde el mismo origen.

### La home cambió o los clientes nuevos no tienen cuentas

- **`home_layout` con `source=fallback` o con `issues` > 0** justo después de publicar: el layout nuevo tiene un error.
  Revertir la versión en Remote Config (§7, *Si algo sale mal*).
- **El error `opening data` en Crashlytics:** falta la plantilla de apertura o es inválida. Publicarla con
  `make deploy-opening` (§7); el próximo inicio de sesión de esos clientes abre sus cuentas.

### Pico de crashes

- **Señales:** alerta de velocidad de Crashlytics, un issue nuevo o una regresión, o "usuarios sin crashes" por debajo
  del 99.5 %.
- **Diagnóstico:** cada issue muestra la versión, el dispositivo y el sistema; con Analytics activo, también los
  eventos previos (las pantallas visitadas) como *breadcrumbs*.
- **Mitigar sin publicar versión:**
  - si el crash ocurre en una función con flag (transferencias o Divisas), apagarla;
  - si es un componente de la home, publicar un layout sin él. Un componente que lanza una excepción no tumba la app:
    se omite y llega como error no fatal (`sdui_component_failed`);
  - si hay un lanzamiento progresivo en curso, pausarlo en Play Console.
- **Si no hay interruptor:** un parche desde `main` (§5), con un test que reproduzca el crash.

### Las notificaciones no llegan

- Revisar que el cliente tenga su token en `users/{uid}.fcmTokens`: se guarda al iniciar sesión con el permiso
  concedido y se quita al cerrar sesión.
- En Android, el emulador necesita Google Play. En iOS no llegan: falta la clave APNs (§7).
- Si la notificación abre la app pero no la pantalla, su `route` no es una ruta de la app: el shell la ignora y no
  registra `push_opened`.
