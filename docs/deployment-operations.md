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
firebase deploy --only firestore:rules --project bi-digital-banking
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

## 5. Versionado y releases

- SemVer en `apps/banking_app/pubspec.yaml` (`version: X.Y.Z+build`).
- Cada PR actualiza `CHANGELOG.md` en `[Unreleased]`; al hacer release se mueve a una versión con fecha y se crea el tag `vX.Y.Z`.

## 6. Observabilidad

_Pendiente:_ Crashlytics (errores no capturados de Flutter y de la plataforma), Performance (trazas HTTP y de arranque), logger con niveles por flavor.

## 7. Operación de contenido (sin publicar versión)

_Pendiente:_ cómo editar las pantallas SDUI y los feature flags en Remote Config, cómo probarlos en dev y cómo revertirlos.

## 8. Runbook de incidentes

_Pendiente:_ qué revisar ante caídas de la API de tipo de cambio, errores de Firebase o crashes masivos.
