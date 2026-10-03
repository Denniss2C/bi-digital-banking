# Bitácora de uso de IA

Registro honesto de cómo se usó IA en el proyecto: qué se pidió, qué produjo, qué se aceptó,
**qué hizo mal y cómo se corrigió**, y qué impacto tuvo.

- Los prompts completos están en [prompts/](prompts/).
- Hay una entrada por paso o PR. Las entradas no se reescriben: si algo resulta incorrecto
  más adelante, se agrega una nota con fecha.
- Las secciones **Revisión del autor** las completa la persona, no la IA.

## Resumen

| ID | Fecha | Paso | Herramienta | Errores de la IA detectados |
|----|-------|------|-------------|-----------------------------|
| [IA-001](#ia-001--paso-1-workspace-con-pub-workspaces-y-melos-8) | 2026-10-03 | Paso 1 · Workspace + Melos 8 | Claude Code (Claude Opus 5.5) | 3 |
| [IA-002](#ia-002--paso-a-makefile-documentación-y-templates-de-github) | 2026-10-03 | Paso (a) · Makefile, docs y templates | Claude Code (Claude Opus 5.5) | 3 |
| [IA-003](#ia-003--paso-b-flavors-dev-y-prod) | 2026-10-03 | Paso (b) · Flavors dev y prod | Claude Code (Claude Opus 5.5) | 4 |

---

## IA-001 · Paso 1: workspace con pub workspaces y Melos 8

- **Rama:** `chore/workspace-melos`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** [prompt maestro](prompts/00-master-prompt.md), paso 1: `pubspec.yaml` raíz
  con `workspace:` y scripts de Melos (`analyze`, `test`, `format`, `build_runner`), `resolution: workspace`
  en cada paquete y dependencias por paquete.

### Qué produjo la IA

- `pubspec.yaml` raíz con los 8 miembros del workspace y los scripts de Melos.
- Pubspecs de todos los paquetes reescritos con `resolution: workspace`, `publish_to: none` y el grafo
  interno `core → design_system → sdui → features → app`.
- Dependencias externas agregadas con `flutter pub add`, así las versiones las resolvió pub en vez de
  escribirse de memoria.
- Se eliminaron los `pubspec.lock` de cada paquete (el workspace usa uno solo en la raíz) y se agregó un `.gitignore` raíz.

### Errores de la IA y cómo se corrigieron

1. **Sintaxis de Melos desactualizada.** Escribió los scripts combinando `run` y `exec`, como se hacía
   hasta Melos 7. Melos 8.9 lo rechaza: el comando ahora va en `exec.command`. Se detectó al ejecutar
   `melos bootstrap`; el propio mensaje de error indicaba la corrección.
2. **YAML inválido.** Generó valores de `description:` con dos puntos sin comillas
   (`Auth feature: onboarding…`), lo que rompe el parseo del pubspec. La primera corrección con `sed`
   también quedó incompleta: usaba la alternancia `\|`, que el `sed` de macOS (BSD) no soporta, y
   hubo que repetirla con `sed -E`.
3. **Flag eliminado en build_runner.** El script `build_runner` usaba `--delete-conflicting-outputs`,
   escrito de memoria. build_runner 2.15 ya no tiene ese flag (borra los outputs en conflicto por
   defecto) y lo ignora con un warning. En el Paso 1 no se ejecutó ese script, así que el error pasó
   desapercibido; se detectó al verificarlo durante el Paso (a) y se corrigió antes del commit del Paso 1.

### Decisiones de la IA para revisar

- No agregó todavía los plugins de Firebase de cada feature (Auth, Firestore, Messaging). Así cada
  commit sigue compilando sin dependencias nativas que aún no se usan. Es una desviación consciente
  del pedido "ajusta los pubspec con sus dependencias": se agregan en el paso de cada feature.

### Verificación

- `melos bootstrap` (8 paquetes), `melos run analyze`, `melos run test` y `melos run format`: OK.
- `flutter build apk --debug` de la app: OK.
- `melos run build_runner`: no se ejecutó en este paso (ver error 3).

### Impacto

- **Productividad:** el paso tomó unos 7 minutos de sesión, con 3 iteraciones causadas por los dos primeros errores.
- **Calidad:** las herramientas (pub, Melos, build_runner) detectaron los tres errores; ninguno llegó al commit.
  Lección: verificar **todos** los scripts que se crean, no solo los que pide el paso.
- **Documentación:** no aplica en este paso.
- **Pruebas:** no se agregaron (paso de configuración); se comprobó que los tests existentes siguen pasando.

### Resultado

- PR #1 mergeado por rebase el 2026-10-03, sin cambios respecto de lo propuesto (árbol idéntico al commit de la IA).

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-002 · Paso (a): Makefile, documentación y templates de GitHub

- **Rama:** `chore/tooling-docs`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** [complemento de estándares](prompts/01-standards-complement.md):
  Makefile, CHANGELOG (Keep a Changelog), README base, `docs/` (arquitectura en Mermaid, ADR,
  despliegue, resiliencia, bitácora de IA), plantilla de PR y CODEOWNERS por dominio.

### Qué produjo la IA

- `Makefile` con 14 targets que delegan en `dart run melos` (sin instalar Melos de forma global).
  `coverage` combina el `lcov.info` de cada paquete en `coverage/lcov.info` con rutas relativas a la raíz.
- `CHANGELOG.md`, la estructura del `README.md` y `docs/` completo, con la plantilla `ADR-000`.
- `.github/pull_request_template.md` y `.github/CODEOWNERS` con un equipo por paquete.
- Los dos prompts guardados en `docs/ai/prompts/`.

### Errores de la IA y cómo se corrigieron

La IA los detectó en una revisión propia antes de entregar el paso:

1. **Diagrama contradictorio.** El primer borrador del flujo de petición resiliente mostraba el
   `ChaosInterceptor` antes que el `RetryInterceptor`, lo opuesto a lo escrito en `resilience.md`.
2. **Etiqueta que GitHub oculta.** Usó `main_<flavor>.dart` como participante de un diagrama Mermaid;
   GitHub interpreta `<flavor>` como una etiqueta HTML y la elimina del render.
3. **Release inventada.** El primer borrador del `CHANGELOG.md` declaraba una versión `0.0.1` con un
   enlace a un tag `v0.0.1` que no existe. Se reemplazó por una sola sección `[Unreleased]`.

### Limitaciones conocidas

- Los equipos `@team-*` de CODEOWNERS son ficticios: GitHub los marca como dueños desconocidos y no
  sirven para exigir revisiones obligatorias. Su propósito es mostrar el ownership por dominio.
- Los diagramas Mermaid **no se validaron con un renderizador**; se revisaron a mano. Hay que confirmar
  que se ven bien en GitHub al abrir el PR.
- Los targets `run-*` y `build-apk-*` dependen de los flavors del Paso (b); antes de ese paso fallan.
- `resilience.md` deja pendiente de confirmar en el Paso 2 si "máx. 3 intentos" significa 3 intentos
  en total o 3 reintentos.

### Verificación

- `make help` lista todos los targets.
- `make coverage` ejecuta los tests con cobertura y genera `coverage/lcov.info` combinado.
- `melos run build_runner`, que usan `make gen` y `make setup`: OK en los 6 paquetes que dependen
  de build_runner (unos 2 minutos, 0 archivos generados porque aún no hay código anotado).
- `make clean` no se ejecutó.

### Impacto

- **Productividad:** la mayor ganancia está en la documentación base y los templates, que son repetitivos de escribir.
- **Calidad:** la plantilla de PR y CODEOWNERS dejan explícitas las reglas de calidad y de dependencias desde el inicio.
- **Documentación:** se creó toda la estructura de `docs/`. Las secciones que dependen de pasos futuros quedaron marcadas como _Pendiente_.
- **Pruebas:** no aplica; `make coverage` deja lista la medición de cobertura.

### Resultado

- PR #2 mergeado por rebase el 2026-10-03, sin cambios respecto de lo propuesto (árbol idéntico al commit de la IA).
- El autor agregó después `CLAUDE.md` (PR #3) con el roadmap y las convenciones; el nombre del PR de tooling en ese
  roadmap (`chore/tooling-and-docs`) no coincidía con los PRs reales y se corrigió en `feat/flavors`.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-003 · Paso (b): flavors dev y prod

- **Rama:** `feat/flavors`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** [complemento de estándares](prompts/01-standards-complement.md), sección Flavors: dev y prod
  en Android e iOS, `main_dev.dart` / `main_prod.dart`, `AppConfig`, una app de Firebase por flavor y herramientas de
  debug solo en dev. El autor eligió hacer Android e iOS juntos y luego pidió que la IA ejecutara también los comandos
  de `flutterfire configure`.

### Qué produjo la IA

- Android: `productFlavors` `dev` (sufijo `.dev`) y `prod`, nombre por `manifestPlaceholders` y un
  `google-services.json` por flavor.
- iOS: script de migración [`tool/setup_ios_flavors.rb`](../../apps/banking_app/tool/setup_ios_flavors.rb):
  configuraciones `<Modo>-<flavor>`, `.xcconfig` por flavor, schemes `dev` y `prod`, deployment target 15.0 y un
  build phase propio que copia el `GoogleService-Info.plist` del flavor.
- Dart: `AppConfig` (`enableDebugTools` solo en dev), `bootstrap`, entry points por flavor y `flutter run` sin
  argumentos en dev. Cinta `DEV` en la app.
- Ejecutó `flutterfire configure` para los dos flavors (registró las apps `.dev` en Firebase) y limpió lo que
  flutterfire deja de más (su build phase en Xcode y entradas obsoletas de `firebase.json`).
- 5 tests nuevos, entre ellos uno que detecta si los nombres de Dart y los nativos se desincronizan.
- ADR-002, sección de flavors en `deployment-operations.md` y configuraciones de VS Code.

### Errores de la IA y cómo se corrigieron

1. **Supuso que iOS usaba CocoaPods.** Creó un `Podfile` con las configuraciones de cada flavor, pero Flutter 3.44
   resuelve todos los plugins con Swift Package Manager. El `pod install` integró CocoaPods al proyecto sin
   necesidad. Se deshizo con `pod deintegrate` y se eliminó el `Podfile`.
2. **Rutas mal armadas en el script de Xcode.** Creó las referencias a los `.xcconfig` como si el grupo `Flutter`
   tuviera ruta propia (no la tiene). Xcode no encontraba los archivos y el bundle ID quedaba sin resolver
   (`Building $(PRODUCT_BUNDLE_IDENTIFIER)`). Se corrigió el script y se volvió a ejecutar sobre el proyecto original,
   para que el resultado fuera reproducible.
3. **Ejecutó dos comandos de Flutter en paralelo.** Un build de iOS y un `analyze` regeneraron a la vez los mismos
   archivos efímeros y uno falló (`Unable to delete .../ephemeral/Packages/.packages`). Se repitió en secuencia.
4. **Trabajó con cambios en el índice dentro de una carpeta compartida.** Otra sesión de Claude trabajaba en la misma
   carpeta, cambió de rama e hizo un commit que se llevó por accidente los renombres de flavors (rama
   `docs/design-reference`, commit `fd09d09`). La IA no había verificado si había otras sesiones activas. Se
   movió el trabajo a un worktree propio (`../bi-digital-banking-flavors`) y se dejó la carpeta compartida limpia.

### Hallazgos que no causó la IA

- El deployment target de iOS (13.0) era incompatible con `firebase_core` 4.x (exige 15.0): iOS no compilaba
  desde que se agregó Firebase.
- Con `--ios-build-config`, flutterfire agrega un script que, en las configuraciones que no conoce (por ejemplo,
  `Release-dev`), **termina sin error y sin copiar el plist**. Por eso se usa un build phase propio.
- Flutter 3.44.7 con Xcode 27: `flutter build ios --simulator` falla porque el `lipo` de Xcode 27 solo acepta una
  arquitectura en `-verify_arch`. Documentado en `deployment-operations.md`, con alternativas.

### Decisiones para revisar

- Un solo proyecto Firebase con una app por flavor: dev y prod comparten datos (ADR-002).
- `flutter run` sin argumentos arranca dev (`default-flavor: dev` y `lib/main.dart`, que reexporta `main_dev.dart`).
- flutterfire mantuvo en `firebase_options_prod.dart` las opciones de web, macOS y Windows que ya existían; las de
  dev solo tienen Android e iOS. No afecta a las plataformas soportadas.

### Verificación

- `melos run analyze` (8 paquetes), `melos run test` y `melos run format`: OK.
- Builds debug de Android: `com.dennis.banking_app.dev` ("BI Dev") y `com.dennis.banking_app` ("BI Banca"),
  verificados con `aapt2 dump badging`.
- Builds debug de iOS para dispositivo sin firma: `com.dennis.bankingApp.dev` ("BI Dev") y
  `com.dennis.bankingApp` ("BI Banca"), con el `GoogleService-Info.plist` de cada flavor dentro del bundle.
- Build **Release-dev** de iOS: el bundle incluye el plist de dev. Es el caso que el script de flutterfire omitía.
- No se ejecutó la app en un emulador o dispositivo; los builds y los bundles generados se inspeccionaron.

### Impacto

- **Productividad:** unos 45 minutos (de 13:55 a 14:40), contra 30 estimados solo para Android. El tiempo extra se
  fue en los problemas de herramientas de iOS y en el choque entre sesiones.
- **Calidad:** salieron a la luz dos problemas latentes (deployment target y script silencioso de flutterfire) antes
  de que afectaran la demo.
- **Documentación:** ADR-002, sección de flavors y problema conocido de Xcode 27 en `deployment-operations.md`.
- **Pruebas:** 5 tests de la app (antes había 1 de ejemplo).

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:
