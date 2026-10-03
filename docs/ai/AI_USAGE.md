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

### Revisión del autor

- Qué acepté:
- Qué corregí o rechacé:
- Valoración del impacto:
