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
| [IA-004](#ia-004--referencia-visual-de-diseño-stitch) | 2026-10-03 | Referencia visual de diseño | Google Stitch + Claude Code (sesión paralela) | 1 |
| [IA-005](#ia-005--alinear-el-proyecto-con-el-diseño-nexo) | 2026-10-03 | Alinear el proyecto con el diseño | Claude Code (Claude Opus 5.5) | 1 |
| [IA-006](#ia-006--core-network-retry-y-chaos) | 2026-10-03 | Paso 2 · core-network (retry y chaos) | Claude Code (Claude Opus 5.5) | 1 |
| [IA-007](#ia-007--design-system-nexo) | 2026-10-03 | Paso 3 · design-system | Claude Code (Claude Opus 5.5) | 1 |
| [IA-008](#ia-008--app-shell-di-router-e-i18n) | 2026-10-03 | Paso 4 · app-shell | Claude Code (Claude Opus 5.5) | 0 |
| [IA-009](#ia-009--ci-con-github-actions) | 2026-10-03 | Paso 5 · CI | Claude Code (Claude Opus 5.5) | 1 (proceso) |
| [IA-010](#ia-010--adr-001-monorepo-modular) | 2026-10-03 | Paso 6 · ADR-001 | Claude Code (Claude Opus 5.5) | 0 |
| [IA-011](#ia-011--auth-dominio-y-datos) | 2026-10-03 | Fase 2 · auth (datos) | Claude Code (Claude Opus 5.5) | 0 |
| [IA-012](#ia-012--auth-ui-sesión-y-redirect) | 2026-10-03 | Fase 2 · auth (UI) | Claude Code (Claude Opus 5.5) | 4 |
| [IA-013](#ia-013--cuentas-datos-en-firestore-y-reglas) | 2026-10-03 | Fase 2 · accounts (datos) | Claude Code (Claude Opus 5.5) | 2 |
| [IA-014](#ia-014--cuentas-ui-y-estados) | 2026-10-03 | Fase 2 · accounts (UI) | Claude Code (Claude Opus 5.5) | 3 |
| [IA-015](#ia-015--transferencias-entre-cuentas-propias) | 2026-10-03 | Fase 2 · transfers | Claude Code (Claude Opus 5.5) | 4 |
| [IA-016](#ia-016--motor-sdui) | 2026-10-04 | Fase 3 · sdui-engine | Claude Code (Claude Opus 5.5) | 4 |
| [IA-017](#ia-017--errores-del-ide-en-build-de-la-raíz) | 2026-10-04 | Errores del IDE en `build/` | Claude Code (Claude Opus 5.5) | 1 |
| [IA-018](#ia-018--home-por-sdui) | 2026-10-04 | Fase 3 · personalization (home) | Claude Code (Claude Opus 5.5) | 5 |

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

---

## IA-004 · Referencia visual de diseño (Stitch)

- **Rama:** `docs/design-reference`
- **Herramientas:** Google Stitch para generar el sistema visual y las pantallas (según el commit), y una sesión
  paralela de Claude Code que hizo el commit. Esta sesión, Claude Code (Claude Opus 5.5), rehízo la rama y abrió el PR.
- **Prompt (resumen):** el de la sesión paralela no quedó registrado en esta bitácora. Hay que completarlo en la
  revisión del autor.

### Qué se agregó

- `docs/design/DESIGN.md`: tokens de "Nexo Digital" (colores Material 3, escala tipográfica Inter, radios y
  espaciado) y guía de marca, color, tipografía, layout, elevación, formas y componentes.
- 7 pantallas de referencia en `docs/design/screens/`: logo, onboarding, autenticación, inicio, cuentas y
  tarjetas, transferencias, divisas y remesas.

### Error y cómo se corrigió

1. **Commit con cambios ajenos.** El primer commit de la sesión paralela (`fd09d09`) se llevó por accidente los
   renombres de flavors que esta sesión tenía en el índice de la carpeta compartida (ver IA-003). La misma sesión
   hizo después un commit limpio (`7383feb`) en el `main` local, que no se podía subir porque `main` está protegida.
   Esta sesión borró la rama local contaminada (no se había subido), recreó `docs/design-reference` desde el `main`
   actualizado con `git cherry-pick 7383feb` y abrió el PR.

### Observaciones para `feat/design-system`

Revisión de la IA sobre `DESIGN.md`:

- **El contraste del botón primario no cumple AA.** El documento pide texto blanco sobre `#F28C28`, que da **2.45:1**
  (AA exige 4.5:1 para texto normal y 3:1 para texto grande). Hay dos opciones que sí cumplen: texto `#0F172A` sobre
  el naranja (7.27:1), o texto blanco sobre el `primary` de Material 3, `#914D00` (6.43:1). El estado presionado
  `#D97706` con texto blanco da 3.19:1.
- **La fuente Inter debe ir empaquetada en la app**, no descargarse en tiempo de ejecución, para que funcione offline.
- **Nombre de marca:** el diseño usa "Nexo Digital", pero los flavors usan "BI Banca" y "BI Dev". Decisión pendiente
  del autor.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-005 · Alinear el proyecto con el diseño Nexo

- **Rama:** `docs/align-design`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** "sigue, pero ya deberías actualizar el `CLAUDE.md` para que se iguale todo el proyecto con el
  diseño".

### Qué produjo la IA

- **`CLAUDE.md`:**
  - en §1, el producto "Nexo Banco Digital";
  - en §4, la sección *Producto y diseño visual*: tokens, tipografía, tema oscuro, navegación con barra inferior, reglas
    de contraste y una tabla de pantallas → features con lo que entra y lo que queda fuera del alcance;
  - una nota en `fx_rates` (sin spreads inventados) y referencias a pantallas en cada ítem del roadmap.
- **Nombres visibles:** "Nexo" (prod) y "Nexo Dev" (dev) en Dart, Gradle y Xcode. Los IDs no cambian, así que Firebase
  no se toca.
- Título del README y CHANGELOG.

### Error de la IA y cómo se corrigió

1. **La revisión de accesibilidad de IA-004 estaba incompleta.** Solo había detectado el texto blanco sobre naranja.
   Al revisar las 7 pantallas y calcular el contraste de cada color de texto aparecieron dos fallas más:
   - el verde `#10B981` de los montos positivos (2.54:1);
   - el rojo `#EF4444` de los gastos (3.76:1).

   Además, para el texto sobre naranja cambió la recomendación de `#0F172A` a navy `#1B2A41` (5.88:1), que también
   cumple AA y respeta la paleta de la marca.

### Decisión inferida (a confirmar por el autor)

- El renombre a "Nexo" se dedujo del pedido "que se iguale todo el proyecto con el diseño". El autor no respondió
  de forma explícita a la pregunta sobre el nombre. Revertirlo implica cambiar tres archivos, y el test de
  sincronización lo valida.

### Verificación

- `flutter analyze --fatal-infos` y `flutter test` de la app: OK (5 tests, incluido el de sincronización de nombres).

### Impacto

- **Productividad:** las próximas sesiones parten de reglas visuales y de alcance escritas en `CLAUDE.md`, sin volver a
  derivarlas de las imágenes.
- **Calidad:** se detectan tres problemas de accesibilidad antes de escribir la UI.
- **Documentación:** el alcance por pantalla queda explícito; sirve para justificar los recortes en la demo.
- **Pruebas:** sin tests nuevos; el existente cubre el renombre.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-006 · core-network: retry y chaos

- **Rama:** `feat/core-network`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** [prompt maestro](prompts/00-master-prompt.md), paso 2: cliente dio con `RetryInterceptor`
  (backoff exponencial con jitter, máx. 3 intentos, solo errores transitorios) y `ChaosInterceptor` configurable en
  runtime (latencia, % de fallos, sin red), con tests unitarios.

### Qué produjo la IA

- `Failure` sellados con equatable y `mapDioException` (`DioException` → `Failure`).
- `RetryPolicy` y `RetryInterceptor`: 3 intentos en total, *full jitter* con tope, solo errores transitorios y métodos
  idempotentes. Cada reintento pasa otra vez por todos los interceptores.
- `ChaosConfig`, `ChaosController` (`ValueNotifier`) y `ChaosInterceptor`: inyecta latencia, HTTP 503 o modo sin red,
  y lee la configuración en cada request.
- `createDioClient`: `[Retry, Chaos?]`. El caos se agrega solo si el shell pasa un controller, es decir, solo en dev.
- 21 tests deterministas (adaptador HTTP falso, `Random` y esperas inyectados).

### Antes de implementar

- **Revisión del código fuente de dio 5.11.** Mostró que un `reject(error)` en `onRequest` **no** ejecuta los
  `onError` del resto de los interceptores. El caos usa `reject(error, true)`. Si no, sus fallos nunca llegarían al
  retry y la demo de resiliencia no probaría nada.
- **Prueba de mutación manual.** Se cambió ese `true` por `false` y los dos tests de integración Chaos + Retry
  fallaron. Con eso se confirma que los tests detectan el problema; después se restauró el código.

### Error de la IA y cómo se corrigió

1. **Estilo que rompía `--fatal-infos`.** El primer borrador asignaba parámetros a campos privados
   (`_dio = dio`, `_delay = delay`), y el lint `prefer_initializing_formals` lo marca como info, que con
   `--fatal-infos` hace fallar el análisis. Se cambió a campos públicos con initializing formals. Además, el `switch`
   del mapper no cubría `DioExceptionType.transformTimeout`, un tipo nuevo de dio 5.11; el análisis lo detectó.

### Decisiones para revisar

- "Máx. 3 intentos" se interpretó como 3 en total (1 + 2 reintentos), configurable con `RetryPolicy.maxAttempts`.
- El modo sin red también se reintenta, porque es un error de conexión y se trata como transitorio. Con la red caída
  de verdad, el usuario espera hasta unos 1.2 s antes del error final.
- `core` no usa anotaciones de injectable todavía: el shell compone las dependencias en `feat/app-shell`.

### Verificación

- `flutter analyze --fatal-infos` sin issues y 21 tests de `core` en verde.
- Prueba de mutación del `reject(error, true)` (ver arriba).

### Impacto

- **Productividad:** unos 25 minutos. Leer el código de dio evitó un error silencioso que habría aparecido recién en la demo.
- **Calidad:** la política de reintentos es configurable y testeable sin red ni esperas reales.
- **Documentación:** `docs/resilience.md` con la política real, el detalle de dio y el mapa de escenarios y tests.
- **Pruebas:** 21 tests nuevos en `core`; se eliminó el test de ejemplo del scaffold.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-007 · Design system Nexo

- **Rama:** `feat/design-system`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** [prompt maestro](prompts/00-master-prompt.md), paso 3: `AppTheme` claro y oscuro con tokens y
  los componentes `AppButton`, `AppCard`, `AppErrorView(onRetry)` y `AppLoading`, siguiendo `docs/design/DESIGN.md` y las
  reglas de `CLAUDE.md` (§4).

### Qué produjo la IA

- Tokens con los valores de `DESIGN.md` y `ColorScheme` explícitos para ambos temas. El oscuro lo derivó la IA
  calculando el contraste de cada par antes de elegir los colores.
- Inter 4.1 empaquetada (descargada de la release oficial `rsms/inter`) con su licencia OFL, y registro de la licencia en
  la pantalla de licencias de la app.
- 5 componentes (incluido `AppEmptyView`, que no estaba pedido pero lo necesita cada pantalla) y `AppSemanticColors`.
- 55 tests:
  - 36 pares de contraste WCAG calculados sobre los temas reales;
  - 2 que documentan por qué el tema se aparta del diseño original;
  - los de temas y componentes, incluidos los de texto al 200%.

### Error de la IA y cómo se corrigió

1. **Bug de accesibilidad en `AppCard`.** Para resumir la tarjeta con `semanticsLabel`, la IA usó
   `excludeSemantics: true`. Eso también descartaba la acción *tap* del `InkWell`: el lector de pantalla anunciaba
   "botón", pero no se podía activar. Lo detectó el test de semántica (`missing actions: [tap]`). Se corrigió
   exponiendo `onTap` en el nodo resumido.

### Verificación

- `melos run analyze`, `format` y `test` en verde (55 tests en `design_system`).
- APK de dev: contiene `packages/design_system/fonts/Inter-*.ttf` y `OFL.txt`, y el `FontManifest` declara
  `packages/design_system/Inter`, la misma familia que usa el tema.
- No se revisó visualmente en un dispositivo; las pantallas reales llegan con las features.

### Impacto

- **Productividad:** unos 35 minutos; las reglas ya escritas en `CLAUDE.md` evitaron rediscutir colores.
- **Calidad:** la accesibilidad queda **verificada por tests**, no solo declarada; cualquier cambio de color que rompa AA
  falla en CI.
- **Documentación:** README del paquete con uso, decisiones de contraste y cómo agregar componentes.
- **Pruebas:** 55 tests nuevos; se eliminó el test de ejemplo del scaffold.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-008 · App shell: DI, router e i18n

- **Rama:** `feat/app-shell`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** [prompt maestro](prompts/00-master-prompt.md), paso 4: Firebase init, get_it, go_router con
  `/splash`, `/login` y `/home` (placeholders), más i18n es/en del [complemento](prompts/01-standards-complement.md) y la
  barra inferior del diseño (`CLAUDE.md` §4).

### Qué produjo la IA

- **DI con injectable.** El entorno de injectable se llama igual que el flavor, así que el `ChaosController`
  (`@dev`) solo existe en dev **por configuración**, sin `if` en el código. El `AppConfig` se registra antes de
  `init`.
- **go_router.** `/splash` → `/login` (placeholder) → `StatefulShellRoute` con 4 pestañas que conservan su estado.
  Los guards por sesión quedan para `feat/auth`.
- **i18n con `gen-l10n`.** Español como plantilla e inglés.
- **Barra inferior con tema AA en el design system.**
- **9 tests nuevos** en la app: navegación, idiomas, resolución de idioma y DI por flavor.

### Hallazgos durante el paso

- La lista de idiomas generada queda en orden alfabético (`[en, es]`). Sin intervención, Flutter usaría **inglés** en
  dispositivos con un idioma no soportado. Se agregó `resolveAppLocale` con respaldo a español y un test que lo
  documenta.
- El diseño marca la pestaña activa con texto naranja sobre blanco (2.45:1). Se movió el acento a la píldora
  indicadora y los textos e íconos usan colores AA.
- En los widget tests el idioma por defecto es `en_US`. Los tests fijan el idioma del dispositivo con
  `localesTestValue` para probar español, inglés y el respaldo.

### Errores de la IA

- No hubo errores que corregir en este paso: el análisis, los tests y el build pasaron al primer intento.

### Decisiones para revisar

- El código generado (injectable y l10n) se versiona para que CI y el IDE funcionen sin correr codegen. La contra es
  que hay que acordarse de regenerarlo.
- El login es un placeholder que entra a la app sin autenticar; se reemplaza en `feat/auth`.

### Verificación

- `melos run format`, `analyze` (8 paquetes) y `test` en verde.
- APK de dev compilado.
- No se ejecutó la app en un emulador.

### Impacto

- **Productividad:** unos 20 minutos, gracias a las reglas y los componentes ya definidos.
- **Calidad:** la exclusión de las herramientas de debug en prod queda garantizada por la DI y cubierta por un test.
- **Documentación:** roadmap y CHANGELOG.
- **Pruebas:** 15 tests en la app (antes 5).

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-009 · CI con GitHub Actions

- **Rama:** `ci/github-actions`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal y a `gh`.
- **Prompt (resumen):** [prompt maestro](prompts/00-master-prompt.md), paso 5: setup de Flutter, melos, bootstrap,
  analyze y test en cada push a `main`. Del roadmap: marcar el check como obligatorio en `main`.

### Qué produjo la IA

- **Workflow** `.github/workflows/ci.yml`:
  - Flutter 3.44.7 fijo con caché;
  - los mismos targets del Makefile que se usan en local;
  - una verificación de que el código generado esté al día;
  - concurrencia por rama y permisos de solo lectura.
- **Versiones vigentes de las actions**, consultadas en GitHub antes de escribir el workflow (`actions/checkout@v7`,
  `subosito/flutter-action@v2`).
- **Check obligatorio en `main`.** La IA leyó primero la protección actual y el `app_id` real del check run (15368,
  GitHub Actions). Después aplicó la protección completa, conservando todas las reglas existentes y agregando solo el
  check.
- **Documentación** del pipeline (con tiempos medidos) y badge de CI en el README.

### Errores de la IA

- No hubo errores en lo entregado. El primer run de CI pasó en verde.
- Un intento de validar el YAML falló porque no había herramientas instaladas (`actionlint`, PyYAML); se validó con
  Ruby.
- **Error de proceso al subir esta entrada.**
  1. El `git push` iba por una tubería a `grep`, que en esta máquina es un alias de `ugrep` y no aceptó el patrón
     `->`. Esa falla cortó el push sin mostrar el error.
  2. Al reintentar, apareció el `HTTP 400` de siempre. Mientras tanto, el autor ya había mergeado el PR #10, y el
     reintento con buffer ampliado **recreó la rama remota borrada**.
  3. La IA no había revisado el estado del PR antes de reintentar.
  4. Se movió el commit a `docs/adr-001` (cherry-pick sobre `main`) y se borró la rama recreada.

  Lección: revisar el estado del PR antes de reintentar un push, y no pasar la salida de `git push` por filtros.

### Decisiones para revisar

- `dart run melos` en vez de "activar melos" de forma global, como decía el prompt: así CI usa la versión del
  lockfile, igual que en local.
- `strict: false`: no exige que el PR esté actualizado con `main` antes de mergear. GitHub igual prueba el merge del
  PR con `main`.
- La verificación del código generado cuesta unos 3 minutos por run. Se aceptó a cambio de versionar ese código con
  garantías.

### Verificación

- Run de CI del PR #10: verde en 6 min 46 s, con todos los pasos en `success`.
- Antes de subir se probó en local el chequeo de código generado (`make gen` + `git diff --exit-code`, sin
  diferencias).
- La respuesta de la API de protección confirma el check obligatorio y que se mantuvieron PR obligatorio, historial
  lineal y la prohibición de force push y de borrado.

### Impacto

- **Productividad:** unos 15 minutos de trabajo más la espera del run.
- **Calidad:** ningún PR puede entrar a `main` sin formato, análisis, tests y código generado en verde.
- **Documentación:** pipeline con pasos, tiempos y una optimización posible.
- **Pruebas:** toda la suite se ejecuta en cada PR.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-010 · ADR-001: monorepo modular

- **Rama:** `docs/adr-001`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code.
- **Prompt (resumen):** [prompt maestro](prompts/00-master-prompt.md), paso 6: ADR-001 que compare un monorepo modular
  con Melos, una app única y repos separados.

### Qué produjo la IA

- [ADR-001](../adr/ADR-001-monorepo-modular.md): problema, tres alternativas con pros y contras, decisión y regla de
  dependencias, trade-offs (incluido el tiempo de CI medido) e impacto a largo plazo, con señales concretas para
  reconsiderar la decisión.
- Un índice de ADRs (`docs/adr/README.md`) y el enlace desde `docs/architecture/dependencies.md`.
- El borrador se escribió mientras corría CI y se completó con los tiempos reales del run.

### Errores de la IA

- No hubo errores en lo entregado.

### Impacto

- **Productividad:** unos 10 minutos.
- **Documentación:** la decisión de estructura queda justificada con datos del propio proyecto (fronteras que hace
  cumplir el compilador, un solo lockfile, CI de unos 7 minutos).

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-011 · Auth: dominio y datos

- **Rama:** `feat/auth-data`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** roadmap de `CLAUDE.md`, ítem `feat/auth` (onboarding, registro, login, sesión persistente,
  logout). La IA propuso partirlo en dos PRs (datos y UI) por tamaño.

### Qué produjo la IA

- **`core`:** `AuthErrorCode` en `AuthFailure` y `KeyValueStore` + `HiveKeyValueStore` (hive_ce).
- **`auth`:**
  - entidad `AppUser`, contratos `AuthRepository` y `OnboardingRepository`;
  - `FirebaseAuthRepository`, que traduce cada código de Firebase a un `Failure` y usa `userChanges()` para que el
    nombre guardado al registrarse se refleje en la sesión;
  - `LocalOnboardingRepository`.
- **Decisión documentada:** sin capa de casos de uso en `auth`, porque serían pasamanos (README del paquete).
- **24 tests nuevos:** 20 en `auth` (Firebase mockeado con mocktail, mapeo de cada código y onboarding) y 4 en
  `core` (store con un Hive real en un directorio temporal).

### Hallazgo durante el paso

- `flutter pub add firebase_auth` hizo que Swift Package Manager dejara una copia del **código fuente del plugin**
  en `build/ios` y `build/macos` (del paquete y de la app). `flutter analyze` (678 issues) y `dart format .` la
  revisaban y fallaban en local. Se corrigió de raíz:
  - `build/**` excluido en el `analysis_options.yaml` de los 8 paquetes;
  - los scripts de formato pasan a revisar solo los archivos `.dart` conocidos por git (`git ls-files`).

  Se verificó que la exclusión funciona con la carpeta presente (regenerada con `pub get`) y que el chequeo de formato
  sigue fallando con un archivo mal formateado de prueba.

  _Nota del 2026-10-04:_ la corrección quedó incompleta. Faltaba la raíz del workspace, que no tenía
  `analysis_options.yaml`, y VS Code mostraba 654 errores de `build/` en la raíz. Ver IA-017.

### Errores de la IA

- No hubo errores en lo entregado. Antes de corregir el problema de `build/` se diagnosticó su causa: se revisaron
  las fechas de creación de la carpeta y la salida de `dart format`.

### Verificación

- `melos run analyze` (8 paquetes sin issues), `format` y `test` en verde. La app compila (APK de dev) con el plugin
  nuevo.
- Los registrants de plugins de la app (macOS y Windows) se regeneraron por el plugin nuevo y se versionan. Si no, el
  chequeo de código generado de CI fallaría.

### Impacto

- **Productividad:** unos 30 minutos, incluido el diagnóstico de `build/`.
- **Calidad:** errores de autenticación tipados (nunca se revela si un email existe) y pruebas sin Firebase real.
- **Documentación:** README del paquete con capas, decisiones y tests.
- **Pruebas:** 24 tests nuevos.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-012 · Auth: UI, sesión y redirect

- **Rama:** `feat/auth-ui` (sobre `feat/auth-data`)
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** "sigue". Segunda mitad de `feat/auth` del roadmap: onboarding, registro, login, logout y
  redirect por sesión, siguiendo las pantallas del diseño.

### Qué produjo la IA

- **`auth`:**
  - `SessionCubit`, `SignInCubit` y `SignUpCubit` con estados `sealed` + equatable;
  - validaciones y mensajes por código de error;
  - `AuthPage` (login y registro) y `OnboardingPage` (3 pasos);
  - textos propios del feature (`AuthLocalizations`, es/en).
- **Shell:**
  - redirect por sesión como función pura (`authRedirect`) y un router que se refresca con el stream de la sesión;
  - Perfil con logout;
  - Hive se abre en `bootstrap` y se inyecta como `KeyValueStore`.
- **Design system:** color `link` (AA) y temas de `TextButton` y `SegmentedButton`, porque el `TextButton` por defecto
  pintaba los enlaces en naranja (2.45:1).
- **Melos:** script `gen-l10n`, incluido en `make gen` y por lo tanto en la verificación de código generado de CI.
- **Tests:** 22 nuevos en `auth` y 9 en la app, entre ellos el flujo completo con un `FakeAuthRepository`: onboarding →
  registro, login → home, logout → login y sesión guardada → home.

### Decisión del autor durante el paso

- freezed estable no se puede usar con este toolchain (detalle en el log de desvíos de `CLAUDE.md`). La IA presentó
  tres opciones y el autor eligió `sealed` + equatable. La IA había agregado freezed como dependencia y lo quitó.

### Errores de la IA y cómo se corrigieron

1. **Helpers de errores enredados.** El primer borrador de los formularios tenía un `as dynamic` y un helper que
   mezclaba el error del email con el de la contraseña. Se detectó al releer el código y se reemplazó por una sola
   función tipada.
2. **Nombres equivocados.** Se usó `SwitchSignIn` (el widget se llama `SwitchModePrompt`) y, en un test,
   `failureMessageForTest` como nombre provisional. Los detectó el analizador.
3. **Tests de la app colgados por 10 minutos.**
   - La IA atribuyó el problema primero a un generador `async*` del fake y lo cambió por `Stream.multi`. **Esa
     hipótesis era incorrecta.**
   - Con logs paso a paso se aisló la causa real: `SessionCubit.close()` **no termina dentro del reloj falso de
     `testWidgets`**, con cualquier tipo de stream. Fuera del reloj falso (bloc_test) cierra bien.
   - Solución: cerrar el cubit con `tester.runAsync` en el teardown.

   Lección: no cambiar código por una hipótesis sin verificarla primero con logs.
4. **Herramientas que ocultaron el diagnóstico.** `timeout` no existe en macOS y `grep` acumula su salida cuando
   escribe a un pipe, así que no se veía el progreso. Se pasó a escribir la salida cruda a un archivo.

### Verificación

- `melos run format`, `analyze` (8 paquetes) y `test` en verde. Sin diferencias en el código generado (`make gen`
  sobre el estado en stage).
- APK de dev compilado.
- **No se probó contra Firebase real en un dispositivo**: los tests usan fakes. Esa prueba queda para el E2E
  (Fase 4) o para el autor con `make run-dev`.

### Impacto

- **Productividad:** unos 60 minutos. Unos 20 se fueron en el cuelgue de los tests, alargado por la hipótesis
  equivocada.
- **Calidad:** el redirect por sesión es una función pura cubierta por una tabla de casos, más el flujo completo en
  widget tests.
- **Documentación:** README de `auth` con presentación, accesibilidad y decisiones; desvío de freezed en
  `CLAUDE.md`.
- **Pruebas:** 31 tests nuevos (auth 42 en total, app 24).

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-013 · Cuentas: datos en Firestore y reglas

- **Rama:** `feat/accounts-data`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal y al CLI de Firebase.
- **Prompt (resumen):** "sigue y dime en qué vamos". Ítem `feat/accounts-data` del roadmap: modelo de Firestore, datos
  iniciales al registrarse y reglas de seguridad.

### Qué produjo la IA

- **Dominio:**
  - `Account` y `AccountTransaction` con el dinero en centavos;
  - un cursor de paginación opaco, para que el dominio no dependa de Firestore;
  - `AccountsSnapshot` con `isFromCache`, para el aviso offline.
- **Datos:**
  - `FirestoreAccountsRepository`: cuentas en tiempo real (los errores llegan como `Left`), movimientos paginados y
    apertura idempotente dentro de una transacción;
  - mapeo defensivo y errores de Firestore traducidos a `Failure`;
  - persistencia offline habilitada de forma explícita.
- **Shell:** `SessionEffects` prepara los datos de apertura al iniciar sesión, componiendo `auth` y `accounts` sin
  que se conozcan.
- **Reglas** de Firestore versionadas y **desplegadas** con el CLI, más el ADR-003 con la decisión de escribir desde
  el cliente en el plan Spark.
- **17 tests nuevos:** 15 en `accounts` con `fake_cloud_firestore` y 2 de los efectos de sesión en la app.

### Decisiones durante el paso

- `fake_cloud_firestore` exige `equatable` 2.x. La IA bajó `equatable` de 3.x a 2.x en todo el monorepo; el código
  solo usa la API común a ambas versiones, y el análisis y los tests completos pasaron después del cambio.
- Sin json_serializable: el mapeo es manual, coherente con la decisión de no usar freezed.

### Errores de la IA y cómo se corrigieron

1. **El test de paginación falló: la segunda página traía 1 elemento en lugar de 4.** Con logs de IDs y cursores se
   encontró la causa: el fake aplica los modificadores **en el orden en que se llaman**, y la query hacía
   `limit()` antes de `startAfterDocument()`. Se reordenó a la forma convencional (`orderBy → startAfter → limit`).
   Firestore real no estaba afectado, pero el código queda más claro.
2. **Un filtro de verificación ocultó un fallo.** Al resumir `melos run analyze` con
   `grep "issues found"`, no se vio un `1 issue found` (singular) en `banking_app`. Se detectó porque aparecían solo
   3 de 8 paquetes, y se corrigió el lint (`prefer_initializing_formals`). Desde ahí las verificaciones usan el
   **código de salida** de cada comando, no filtros de texto.

### Verificación

- `melos run analyze`, `test` y `format` con código de salida 0. Sin diferencias en el código generado. APK de dev
  compilado.
- Reglas compiladas y publicadas en el proyecto (`firebase deploy --only firestore:rules`).
- **Pendiente:** probar la apertura de cuentas contra Firestore real. Llega con la UI de cuentas o con el E2E.

### Impacto

- **Productividad:** unos 60 minutos.
- **Calidad:** contrato de datos protegido por reglas (libro inmutable, validación de forma y de propiedad) y errores
  de datos que no rompen la app.
- **Documentación:** ADR-003, README de `accounts` y despliegue de reglas en `deployment-operations.md`.
- **Pruebas:** 17 tests nuevos.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-014 · Cuentas: UI y estados

- **Rama:** `feat/accounts-ui`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** "sigue". Ítem `feat/accounts-ui`: lista de cuentas, saldo y movimientos paginados con todos
  los estados, según `cuentas_y_tarjetas_*` y la regla de los 5 estados.

### Qué produjo la IA

- **Pantallas:** `AccountsPage` (saldo total en tarjeta hero y tarjetas por cuenta) y `AccountDetailPage` (saldo en
  vivo y movimientos con scroll infinito), con los 5 estados más el error al cargar más.
- **Cubits:**
  - `AccountsCubit`: stream de cuentas con reintento;
  - `TransactionsCubit`: paginación, cargar más y fallo de cargar más, sin perder la lista ya mostrada.
- **Piezas compartidas:** `formatUsd` en `core`, `AppOfflineBanner` en el design system y `isFromCache` en cada página
  de movimientos.
- **Shell:** detalle como ruta anidada (`/accounts/:id`), así se mantiene la barra inferior.
- **25 tests nuevos:** 14 en `accounts`, 1 de flujo en la app y los de `core` y el design system.

### Errores de la IA y cómo se corrigieron

1. **Contraste roto en la tarjeta hero.** Los textos usaban estilos del tema, cuyo color `onSurface` (oscuro) pisa el
   color claro de la tarjeta hero: habría quedado texto oscuro sobre navy. La IA lo notó al releer el código, antes
   de cualquier test. Se corrigió con `onHeroSurface` en cada texto, se agregó un test que verifica esos colores y se
   comprobó con una mutación que el test falla si el bug vuelve. La trampa quedó documentada en el README del
   design system.
2. **Constructores que rompían el lint** (`prefer_initializing_formals`) y un script de reemplazos que falló a mitad
   de camino. Se rehízo con ediciones puntuales.
3. **Expectativas de test mal planteadas:**
   - la hora en español es `9:05`, no `09:05`;
   - con una sola cuenta, el total y el saldo de la cuenta coinciden, así que `find.text` encontraba dos widgets.

   Se corrigieron los tests acotando la búsqueda; la app no tenía el problema.

### Verificación

- `format`, `analyze` y `test` con código de salida 0; código generado sin diferencias; APK de dev compilado.
- **Sin prueba visual en un dispositivo.** Pendiente: recorrer la pestaña con `make run-dev` contra Firestore real.

### Impacto

- **Productividad:** unos 60 minutos.
- **Calidad:** los 5 estados implementados y testeados. El contraste del hero queda protegido por un test probado con
  mutación.
- **Documentación:** README de `accounts` (presentación y estados) y del design system (trampa del hero), y
  `resilience.md`.
- **Pruebas:** `accounts` 28, app 27.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-015 · Transferencias entre cuentas propias

- **Rama:** `feat/transfers`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** "listo, continua". Ítem `feat/transfers`: transferencia entre cuentas propias con
  `runTransaction`, según la pantalla `transferir_dinero_*` (opción "A cuentas Nexo").

### Qué produjo la IA

- **Dominio:**
  - `TransferBetweenOwnAccounts`: cuentas distintas, monto mayor a cero, máximo $5,000.00 y concepto de hasta 60
    caracteres;
  - `TransferReceipt` y `TransferError`;
  - `ValidationFailure` en `core`.
- **Datos:** `transfer` con `runTransaction`. Lee y después escribe, rechaza el saldo insuficiente con datos frescos y
  escribe débito y crédito con el mismo `transferId`, todo o nada.
- **Idempotencia**, agregada durante el paso y fuera del plan: la clave la genera el repositorio (`newTransferId`), el
  cubit la reutiliza en cada reintento y la transacción no vuelve a escribir si el débito ya existe.
- **Presentación:**
  - `TransferCubit`: formulario, validaciones, envío y reintento con la misma clave;
  - `TransferPage`: formulario según el diseño y comprobante;
  - `parseAmountCents`: acepta `150,50` y `1,500.00`;
  - botón Transferir en la pestaña Cuentas.
- **Shell:** ruta `/accounts/transfer`, declarada antes de `/:accountId`.
- **41 tests nuevos:** 40 en `accounts` y 1 de flujo en la app.

### Errores de la IA y cómo se corrigieron

1. **Riesgo de cobro doble que el diseño inicial no contemplaba.** La primera versión creaba el id de la
   transferencia dentro de la transacción. Si la respuesta del commit se pierde, Firestore reintenta la transacción y
   la habría aplicado dos veces; lo mismo si el usuario reintentaba después de un error de red. La IA lo detectó al
   revisar el flujo offline, antes del PR, y agregó la clave de idempotencia (unos 25 minutos fuera del plan).
2. **Formulario en un `ListView` perezoso.** Un widget test no encontraba el botón Transferir porque no se construye
   fuera de pantalla. Al analizarlo apareció un bug real: en un teléfono pequeño, el campo de concepto se destruye al
   salir de pantalla y pierde el texto. Se cambió a `SingleChildScrollView` + `Column`. No hay un test que reproduzca
   la pérdida del texto; el motivo quedó en un comentario.
3. **Emit después de cerrar el cubit.** Si el usuario sale de la pantalla mientras la transferencia está en curso, el
   cubit se cierra y el `emit` final lanzaba un `StateError`, aunque la transferencia terminara bien. La IA lo vio al
   revisar el código final. Se agregó `if (isClosed) return;` con su test, comprobado con una mutación. El mismo
   problema existe en `SignInCubit`, `SignUpCubit` y `TransactionsCubit`, de pasos anteriores; quedó anotado en el
   roadmap (`feat/resilience`) para no mezclarlo en este PR.
4. **Tests y scripts mal planteados:**
   - un test mezclaba dos escenarios en el mismo árbol de widgets. El segundo `pump` reutilizaba el cubit del primero
     (`BlocProvider.create` corre una sola vez), así que fallaba aunque la pantalla estaba bien. Se separó en dos
     tests;
   - un script de reemplazos insertó un argumento dos veces, porque un patrón con 6 espacios también coincidía dentro
     de las líneas con 8. El análisis lo detectó y se corrigió a mano;
   - un primer intento de correr los tests usó `timeout`, que no existe en macOS: no corrió nada ni mostró salida. Se
     repitió verificando el código de salida.

### Verificación

- `make format-check`, `make analyze` y `make test` con código de salida 0; `make gen` sin diferencias; APK de dev
  compilado.
- **Mutaciones:** 14 cambios en la lógica y 13 detectados por algún test. Entre ellos: sin chequeo de saldo (servidor
  y cliente), sin protección contra el doble envío, límite con `>=`, coma decimal ignorada, ruta declarada después de
  `:accountId`, sin el chequeo de reintento en la transacción, id nuevo en cada envío y sin el guard de `isClosed`.
  - **Sobrevive uno:** quitar la renovación de la clave en `restart()`. Después de reiniciar, el monto queda vacío y
    todo envío válido exige editar, lo que ya renueva la clave. Se mantiene como línea defensiva.
- **Sin prueba en un dispositivo ni contra Firestore real:** el fake no reproduce el modo offline ni las reglas.
  Pendiente: transferir con `make run-dev` y probar en modo avión.

### Impacto

- **Productividad:** algo más de la hora estimada; la idempotencia sumó unos 25 minutos.
- **Calidad:** transferencias atómicas e idempotentes, con las mismas reglas en la UI y en el dominio.
- **Documentación:** README de `accounts`, `resilience.md` (reintentos sin cobros dobles y transferencias sin
  conexión) y CHANGELOG.
- **Pruebas:** `accounts` 68, app 28.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-016 · Motor SDUI

- **Rama:** `feat/sdui-engine`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** "sigue". Ítem `feat/sdui-engine`: parser, registry, render, fallback y tests, según §4
  "Personalización + SDUI" de `CLAUDE.md` y la pantalla `inicio_*`.

### Qué produjo la IA

- **Contrato JSON** versionado (`schemaVersion`) con `id` opcional por componente, documentado en el README de `sdui`.
- **Motor:**
  - `parseSduiLayout`: tolerante por componente; rechaza el documento solo si no es JSON, tiene la forma incorrecta o
    es de un esquema más nuevo;
  - `SduiProps`: lecturas tipadas que nunca lanzan, más `require*`; textos traducibles;
  - `SduiAction`: `navigate`, solo a rutas internas;
  - `SduiRegistry`: un tipo registrado dos veces falla;
  - `SduiView`: frontera de error por componente, claves por `id` y tolerancia a ids repetidos;
  - `resolveSduiLayout`: elige entre el layout remoto y el embebido, y devuelve el motivo.
- **Componentes estándar:** `promo_banner` (tonos semánticos AA) y `quick_actions` (columnas que se adaptan al tamaño
  del texto).
- **ADR-004** (alternativas: rfw, JSON de widgets y WebView) y el README del paquete con el contrato y el catálogo.
- **42 tests nuevos.** Reemplazan al test de ejemplo de `flutter create`.

### Errores de la IA y cómo se corrigieron

1. **Atajos que se cortaban con texto grande.** La primera versión de `quick_actions` usaba 4 columnas fijas y
   etiquetas con elipsis: al 200% de texto, "Transferir" quedaba cortado, contra la regla de `CLAUDE.md` ("texto
   escalado sin cortes"). La IA lo detectó al revisar el componente, antes de los tests. Ahora usa dos columnas con
   texto grande, con un test que lo verifica.
2. **Un test que no probaba lo que decía.** El test del idioma de respaldo esperaba español para `fr`, pero pasaba
   solo porque `es` era la primera clave del mapa: sin el respaldo a español también pasaba. Se detectó al planear las
   mutaciones. Se cambió el orden de las claves y ahora la mutación se detecta.
3. **API deprecada y un archivo sin formatear.** Un test usaba `containsSemantics`, deprecado en esta versión de
   Flutter; el análisis lo marcó y se cambió por `isSemantics`. El cambio se hizo con un reemplazo de texto que dejó
   el archivo sin formatear, y `make format-check` lo detectó.
4. **Conflicto al verificar un commit intermedio con `git stash`.** Para probar el primer commit por separado, la IA
   guardó el resto de los cambios con `git stash`. Al restaurarlos, dos archivos nuevos que tenían una versión
   intermedia en el índice entraron en conflicto. No se perdió nada: el stash quedó guardado, se comparó archivo por
   archivo con el árbol de trabajo antes de rehacer el commit, y el resultado final es idéntico. Desde ahora, los
   commits intermedios se verifican haciendo checkout del commit, sin stash.

### Verificación

- `make format-check`, `make analyze` y `make test` con código de salida 0; `make gen` sin diferencias; APK de dev
  compilado.
- **Mutaciones: 11 de 11 detectadas.** Sin frontera de error, sin protección de ids repetidos, claves solo por
  posición, aceptar esquemas más nuevos, aceptar un remoto sin nada que mostrar, permitir rutas `//host`, sin respaldo
  a español, botón sin acción soportada, colores de texto del tema en el banner (habría fallado AA sobre navy),
  columnas fijas y registro duplicado que reemplaza.
- **El motor todavía no se ve en la app:** la home renderizada por SDUI llega en `feat/personalization`.

### Impacto

- **Productividad:** alrededor de una hora para el motor, dos componentes, la documentación y los tests.
- **Calidad:** el JSON remoto no puede romper la pantalla, y cada componente cumple AA por construcción, con tests
  que lo comprueban.
- **Documentación:** contrato y catálogo en el README de `sdui`, ADR-004 y CHANGELOG.
- **Pruebas:** `sdui` 42.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-017 · Errores del IDE en build/ de la raíz

- **Rama:** `chore/ignore-root-build`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** "sigue y mira los errores que me salen en el build".

### Qué produjo la IA

- **Diagnóstico con los datos del IDE.** Leyó los diagnósticos del panel Problems de VS Code: 654 errores, todos en
  `build/ios/SourcePackages` y `build/macos/SourcePackages` de la raíz. Son copias de `firebase_auth` y
  `cloud_firestore` (con sus tests y ejemplos) que deja Swift Package Manager. Ninguno estaba en código del proyecto.
- **Causa comprobada, no supuesta:** se borró la carpeta y `make bootstrap` la volvió a crear. Resolver dependencias en
  la raíz la regenera siempre; los paquetes ya excluían `build/**`, pero la raíz no tenía `analysis_options.yaml`.
- **Corrección:** `analysis_options.yaml` en la raíz que excluye `build/**`. Después del cambio, VS Code no reporta
  errores; solo queda un aviso informativo de la extensión de Java para recargar Gradle.
- **Builds reales** de Android (APK de dev) e iOS (dispositivo, sin firma): los dos compilan sin errores. Android
  muestra un aviso de Flutter porque `firebase_auth` y `firebase_core` aplican el Kotlin Gradle Plugin. Ya usamos sus
  últimas versiones, así que quedó documentado como riesgo conocido en `deployment-operations.md`.

### Errores de la IA y cómo se corrigieron

1. **Corrección incompleta en IA-011.** Al excluir `build/**` en los 8 paquetes, la IA no revisó la raíz del
   workspace, que el IDE analiza como otro contexto. Además, la última regeneración de la carpeta (a las 00:44) vino de
   un `flutter pub get` que la IA corrió en la raíz durante IA-016.

### Verificación

- Diagnósticos de VS Code antes (654 errores) y después (0 errores) del cambio.
- `make analyze` y `make format-check` con código de salida 0.
- `flutter build apk --flavor dev --debug` y `flutter build ios --flavor dev --no-codesign --debug` con código de
  salida 0.

### Impacto

- **Productividad:** unos 15 minutos.
- **Calidad:** el panel Problems vuelve a mostrar solo problemas reales del proyecto.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:

---

## IA-018 · Home por SDUI

- **Rama:** `feat/home-sdui`
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code, modo agente con acceso a la terminal.
- **Prompt (resumen):** "sigue". Primera de las dos partes de `feat/personalization`; el autor eligió dos PRs con el
  alcance completo después de que la IA avisó que el ítem costaría más de lo planeado.

### Qué produjo la IA

- **Home (Inicio) en el shell:**
  - saludo con el nombre de la sesión y `SduiView` con el layout embebido, que replica `inicio_*`;
  - deslizar hacia abajo recrea los componentes y cada uno recarga;
  - las acciones `navigate` solo abren pantallas de la app (`AppRoutes.isAppLocation`).
- **`createHomeRegistry`:** junta los componentes estándar de `sdui` con los de accounts. Los features siguen sin
  conocerse entre sí.
- **accounts:**
  - `balance_card`: reutiliza `BalanceHeroCard` y `AccountsCubit`;
  - `tx_list`: `RecentMovementsCubit` junta todas las cuentas, vuelve a pedir datos solo si cambia un saldo y descarta
    las respuestas que llegan fuera de orden.
- **21 tests nuevos:** 13 en `accounts` y 8 en la app, incluido el contrato del layout embebido (sin issues, todos sus
  tipos registrados salvo `fx_widget`, y todas sus rutas válidas).
- **Verificación visual:** la home renderizada con fuentes reales (Inter e íconos) en un test temporal, en tema claro y
  oscuro, comparada con `inicio_*`.

### Errores de la IA y cómo se corrigieron

1. **Guardia de rutas incompleta.** `isAppLocation` miraba solo el path, así que aceptaba
   `https://evil.example/accounts`. Lo detectó un test que la IA escribió en el mismo paso; ahora rechaza esquema y
   host. El motor SDUI ya bloqueaba esas rutas, pero la guardia del shell debe sostenerse sola.
2. **Chevron antes del texto en el botón de la promo** (venía del PR #17). `AppButton` solo admite un ícono inicial y
   ningún test lo veía. Se detectó en la verificación visual y se quitó el ícono.
3. **Un test colgado 30 segundos.** El `tearDown` cerraba un `StreamController` de una sola suscripción que ningún
   test escuchó, y su `close()` nunca completa. Se cambió a uno broadcast.
4. **Errores menores** que marcaron el IDE y el análisis: un tipo inexistente (`AccountTransactionLike`) y un `if`
   sin llaves.
5. **PRs en paralelo que agregaban texto al mismo archivo.** Este PR y #18 agregaban una entrada al final de este
   archivo. La IA avisó el orden de merge, pero al usar "Update branch" en GitHub se creó un commit de merge, y como
   `main` solo acepta merges por rebase, el PR quedó bloqueado (y el #20, apilado encima, también). Se resolvió
   rebasando en local, dejando las entradas en orden, y reemplazando la rama. Lección: no abrir en paralelo PRs que
   agregan texto al mismo lugar de un archivo; si hace falta, apilarlos y rebasar después de cada merge.

### Verificación

- `make format-check`, `make analyze` y `make test` con código de salida 0; `make gen` sin diferencias; APK de dev
  compilado.
- **Mutaciones: 10 de 10 detectadas.** Pedir datos en cada snapshot, orden invertido, sin límite, sin descartar
  respuestas viejas, error que oculta los movimientos ya cargados, perder la marca de caché, `balance_card` sin
  acción, límite sin acotar, sin aviso offline en el saldo y aceptar ubicaciones externas.
- **Pendiente:** ningún test detecta si `HomePage` deja de usar la guardia de rutas. Se cubrirá en
  `feat/remote-personalization`, cuando el layout pueda venir del servidor con una ruta inválida.
- **Sin prueba en un dispositivo con sesión.** La app del emulador no tenía sesión y crear un usuario en Firebase no
  estaba autorizado, así que la verificación visual fue con el test temporal.

### Impacto

- **Productividad:** alrededor de una hora.
- **Calidad:** la home ya es server-driven; un componente desconocido o roto no afecta al resto, y los movimientos
  se actualizan solos después de una transferencia.
- **Documentación:** READMEs de `sdui` y `accounts`, CHANGELOG y `CLAUDE.md`.
- **Pruebas:** `accounts` 81, app 36.

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:
