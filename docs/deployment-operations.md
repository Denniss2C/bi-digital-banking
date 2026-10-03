# Despliegue y operación

> Estado: estructura inicial. Las secciones marcadas _Pendiente_ se completan en el paso que las implementa.

## 1. Entornos (flavors)

| Flavor | Application ID / Bundle ID | Firebase app | Panel de debug / Chaos |
|--------|----------------------------|--------------|------------------------|
| `dev`  | `com.dennis.banking_app.dev` | app dev (mismo proyecto) | ✅ |
| `prod` | `com.dennis.banking_app` | app prod (mismo proyecto) | ❌ |

_Pendiente (Paso b): entry points, `AppConfig`, schemes de iOS y comandos `flutterfire configure` por flavor._

## 2. Configuración y secretos

- No hay secretos en el repositorio. Las opciones de cliente de Firebase (`firebase_options_*.dart`)
  **no son secretos**: identifican la app ante Firebase. La protección real viene de:
  - Restricciones de API key en Google Cloud Console (por package name + SHA-1 en Android y por bundle ID en iOS).
  - Reglas de seguridad de Firestore.
  - _Planificado:_ App Check.
- Los valores que cambian sin publicar versión (feature flags, contenido SDUI) viven en Remote Config.

## 3. Integración continua

_Pendiente (Paso 5):_ GitHub Actions en cada push y PR a `main`: `melos bootstrap` → `analyze` → `format` → `test`.

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
