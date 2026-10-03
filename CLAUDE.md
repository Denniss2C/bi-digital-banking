# CLAUDE.md — Contexto del proyecto `bi-digital-banking`

> Este archivo es la fuente de verdad para el asistente de IA que trabaja en este repo.
> Léelo completo al inicio de cada sesión. Mantén actualizada la sección **Roadmap** (marca `[x]` al terminar cada ítem y anota desvíos).

---

## 1. Qué es este proyecto

Prueba técnica para el puesto **Mobile Flutter Senior Developer** en **Banco Internacional (Ecuador)**.

**Entrega:** lunes 5 de octubre de 2026, en la noche (hora Ecuador, UTC-5).
**Repo:** https://github.com/Denniss2C/bi-digital-banking (público)
**Firebase project ID:** `bi-digital-banking` (Firestore en `nam5`)

### El reto
Construir una **plataforma financiera digital de nueva generación**, sin atención física, que:
- Evolucione hacia un ecosistema de **múltiples dominios funcionales administrados por equipos independientes**.
- **Adapte la experiencia** dinámicamente según contexto, perfil, comportamiento o preferencias del usuario.
- Permita **incorporar nuevas experiencias, contenidos o componentes visuales sin publicar una nueva versión** de la app.
- Integre productos financieros y no financieros, propios o de terceros.

### Alcance mínimo (obligatorio)
1. Onboarding y autenticación de clientes
2. Gestión de cuentas, saldos y movimientos
3. Personalización dinámica de experiencia, contenido o funcionalidades
4. Integración con al menos un servicio o micro app externo relevante
5. Notificaciones push
6. Explicar monitoreo en producción y detección de problemas operativos / de UX
7. Describir comportamiento ante conectividad limitada, alta latencia o indisponibilidad parcial
8. Pruebas unitarias, de widgets y **al menos un flujo E2E crítico**
9. Documentar el uso de IA y su impacto en productividad, calidad, documentación y pruebas
10. **Demostrar** el comportamiento degradado: estados de carga, reintentos, caché y recuperación

### Entregables
1. Código fuente con historial de desarrollo
2. README con instrucciones reproducibles (configurar, ejecutar, probar, colaborar)
3. Documentación de arquitectura y decisiones técnicas (ADRs)
4. Documentación de despliegue y operación
5. Demostración funcional

### Criterios de evaluación
| Categoría | Qué miran |
|---|---|
| Arquitectura | Modularidad, escalabilidad, mantenibilidad, justificación, evolución |
| Calidad de ingeniería | Patrones, gestión de estado, pruebas, seguridad, observabilidad |
| UX | Personalización, consistencia, accesibilidad, interacción |
| Documentación | Diagramas, decisiones, riesgos, trade-offs |
| Pensamiento de producto | Priorización, valor, escenarios degradados, decisiones de alcance |
| IA y automatización | Uso efectivo de herramientas |
| Versionamiento | Trunk Based Development, frecuencia de commits, calidad del historial |

### Restricciones críticas
- **NO** se evalúan positivamente soluciones solo con datos simulados o respuestas estáticas. Debe haber interacción real con servicios (Firebase + API externa real).
- Tecnología principal: **Flutter**.
- En la demo pedirán **cambios en vivo, diagnóstico de una falla o ajuste de un test**. Dennis debe entender cada línea: explica las decisiones y evita magia innecesaria.

### Bonus (solo si sobra tiempo)
- Personalización avanzada o asistente (p. ej. asistente financiero con IA sobre los movimientos)
- Experiencias generadas dinámicamente (SDUI ya lo cubre en parte)
- Automatizaciones de desarrollo, pruebas, despliegue o documentación

---

## 2. Stack

- Flutter estable, Dart 3 (>= 3.6), null safety
- Monorepo: **Melos 8.x + Dart pub workspaces** (sin `melos.yaml`; la config está en el `pubspec.yaml` raíz; cada paquete usa `resolution: workspace`)
- Estado: `flutter_bloc` (Bloc/Cubit) + `equatable`
- Modelos/estados: `freezed` + `json_serializable`
- Arquitectura: Clean Architecture por feature (`data` / `domain` / `presentation`)
- DI: `get_it` + `injectable`
- Navegación: `go_router`
- Backend: Firebase (Auth, Cloud Firestore, Cloud Messaging, Remote Config, Crashlytics, Performance, Analytics)
- HTTP externo: `dio` con interceptores
- Caché local: `hive_ce`
- Errores: `Either` de `fpdart` + Failures tipadas (`NetworkFailure`, `ServerFailure`, `CacheFailure`, `AuthFailure`)
- i18n: `flutter_localizations` + ARB (es por defecto, en)
- Tests: `bloc_test`, `mocktail`, `flutter_test`, `integration_test`
- CI: GitHub Actions

## 3. Estructura

```
apps/banking_app                 -> shell: composición, routing, DI global, flavors
packages/core                    -> network (dio + RetryInterceptor + ChaosInterceptor), errores, logger, connectivity
packages/design_system           -> tokens, tema claro/oscuro, componentes accesibles
packages/sdui                    -> motor Server-Driven UI: JSON -> registry de widgets -> render
packages/features/auth           -> onboarding, registro, login
packages/features/accounts       -> cuentas, saldos, movimientos, transferencias
packages/features/notifications  -> FCM
packages/features/fx_rates       -> micro app externa (tipo de cambio, API pública real)
docs/                            -> architecture/, adr/, ai/, deployment-operations.md, resilience.md
```

**Reglas de dependencia:** los features NO dependen entre sí; solo de `core`, `design_system` y `sdui`. La comunicación entre features pasa por el shell (rutas y contratos definidos en `core`).

## 4. Diseño de referencia (ajustable, documentar cambios en ADR)

### Modelo de datos (Firestore)
```
users/{uid}                         name, email, segment, onboardingCompleted, preferences{}, fcmTokens[]
users/{uid}/accounts/{accountId}    type (savings|checking), maskedNumber, balance, currency, alias
users/{uid}/accounts/{id}/transactions/{txId}
                                    amount, type (credit|debit), description, category, createdAt, balanceAfter
layouts/{screenId}                  JSON SDUI por pantalla/segmento (alternativa o complemento a Remote Config)
```
- Script de seed para crear datos iniciales al registrarse (o Cloud Function `onUserCreate` si se habilita Blaze).
- Transferencia entre cuentas propias con `runTransaction` (procesamiento real, no estático).
- **Reglas de seguridad** de Firestore: cada usuario solo lee/escribe su propio árbol. Versionar en `firebase/firestore.rules`.

### Personalización + SDUI
- Remote Config: `home_layout` (JSON) con condiciones por segmento de usuario (`new_user`, `saver`, `traveler`, etc.) y feature flags (`feature_fx_enabled`, `feature_transfers_enabled`, `feature_ai_assistant_enabled`).
- El JSON describe una lista de componentes: `{ "type": "balance_card" | "quick_actions" | "promo_banner" | "fx_widget" | "tx_list", "props": {...} }`.
- `sdui` tiene un `WidgetRegistry`: tipo desconocido → se ignora sin romper (forward compatibility). Fallback a un layout por defecto embebido si Remote Config falla.
- Demostración clave: cambiar el JSON en la consola → la home cambia sin publicar la app.

### Resiliencia
- `RetryInterceptor`: backoff exponencial con jitter, máx. 3 intentos, solo errores transitorios/idempotentes.
- `ChaosInterceptor` + panel de debug (**solo flavor dev**): latencia artificial, % de fallos, modo sin red.
- Firestore con persistencia offline. API externa con caché `hive_ce` (stale-while-revalidate + timestamp "actualizado hace X").
- Toda pantalla: `loading`, `success`, `empty`, `error` (con reintento), `offline` (caché + banner).

### Micro app externa
- `fx_rates`: tipo de cambio desde una API pública real sin API key (verificar disponibilidad; p. ej. open.er-api.com). Debe funcionar con caché y degradarse con elegancia.

### Push
- FCM: pedir permiso, guardar token en `users/{uid}.fcmTokens`, manejar foreground/background/tap → deep link con go_router.
- Envío: desde la consola de Firebase para la demo; opcional Cloud Function al crear un movimiento (requiere plan Blaze).
- Demo en **Android** (iOS requiere clave APNs; documentarlo).

### Observabilidad
- Crashlytics (errores no capturados + `recordError` en Failures relevantes), Performance (traces de pantallas y llamadas HTTP), Analytics (eventos de negocio y de UX).
- Documentar en `docs/deployment-operations.md`: métricas, alertas, SLOs propuestos y cómo detectar problemas de UX.

---

## 5. Convenciones de trabajo

### Git — Trunk Based Development con ramas cortas
- `main` está protegida: requiere PR, historial lineal, sin force push. Merge **solo con rebase** (`gh pr merge --rebase`).
- Ramas de vida corta (horas, máx. 1 día): `feat/...`, `fix/...`, `chore/...`, `docs/...`, `test/...`, `ci/...`
- Commits pequeños y frecuentes con **Conventional Commits**.
- Lo no terminado entra a `main` detrás de un feature flag.
- Cada PR usa `.github/pull_request_template.md` y actualiza `CHANGELOG.md` (Keep a Changelog + SemVer).
- Antes de cada PR: `make analyze && make test`.

### Al trabajar conmigo (Dennis)
1. **Analiza antes de proponer cambios.** Resume el diseño en 5-10 líneas y luego implementa.
2. **Depura con logs antes de aplicar fixes.** No adivines.
3. Un paso por vez. Al inicio, dime el **nombre de la rama**; al final, los **commits sugeridos** y el **título/descripción del PR**.
4. Archivos completos con su ruta.
5. Tests para toda lógica nueva (blocs, repositorios, usecases).
6. Decisiones de arquitectura → ADR corto en `docs/adr/` (Problema, Alternativas, Decisión, Trade-offs, Impacto a largo plazo).
7. Código y comentarios en inglés; documentación en español.
8. Si algo va a costar más de lo planeado, avísame y propón un recorte antes de seguir.

### Registro de uso de IA
Después de cada paso relevante, agrega una entrada a `docs/ai/AI_USAGE.md`:
`fecha | tarea | herramienta | prompt resumido | qué se aceptó | qué se corrigió y por qué | impacto (productividad, calidad, docs, pruebas)`.
Sé honesto: incluye lo que la IA hizo mal. Guarda los prompts de fase en `docs/ai/prompts/`.

---

## 6. Roadmap

Estado al iniciar este archivo (sáb 3 oct, 13:45):
- [x] Proyecto Firebase creado (Auth email/password, Firestore `nam5`, FCM API v1)
- [x] Scaffolding: `apps/banking_app` + `packages/*` con `flutter create`; `flutterfire configure`
- [x] Repo en GitHub, protección de `main`, merge solo por rebase
- [x] PR #1 `chore/workspace-melos`: pub workspace, scripts de Melos 8 y grafo de dependencias entre paquetes
- [x] PR #2 `chore/tooling-docs`: Makefile, docs/, CHANGELOG, README base, templates de GitHub, CODEOWNERS
- [x] PR #3 `docs/claude-context`: este archivo

### Fase 1 — Base (sábado, meta 17:00)
- [ ] `feat/flavors`: dev/prod (Android productFlavors + iOS schemes), `main_dev.dart`/`main_prod.dart`, `AppConfig`, Firebase por flavor
  - Nota: el bundle ID de iOS es `com.dennis.bankingApp` porque iOS no admite `_`; el de dev sería `com.dennis.bankingApp.dev`.
- [ ] `feat/core-network`: cliente dio + RetryInterceptor + ChaosInterceptor + tests
- [ ] `feat/design-system`: tema claro/oscuro, tokens, AppButton, AppCard, AppErrorView(onRetry), AppLoading
- [ ] `feat/app-shell`: Firebase init, get_it/injectable, go_router (/splash, /login, /home), i18n es/en
- [ ] `ci/github-actions`: analyze + test en push y PR → luego marcar el check como obligatorio en `main`
- [ ] `docs/adr-001`: monorepo modular (Melos) vs app única vs repos separados

### Fase 2 — Núcleo funcional (sábado noche)
- [ ] `feat/auth`: onboarding (2-3 pantallas), registro, login, sesión persistente, logout, redirect con go_router
- [ ] `feat/accounts-data`: modelo Firestore, seed al registrarse, reglas de seguridad
- [ ] `feat/accounts-ui`: lista de cuentas, saldo, movimientos (paginados) con todos los estados
- [ ] `feat/transfers`: transferencia entre cuentas propias (`runTransaction`) — **recortable**

### Fase 3 — Diferenciadores (domingo)
- [ ] `feat/sdui-engine`: parser + registry + render + fallback + tests
- [ ] `feat/personalization`: Remote Config por segmento + feature flags; home renderizada por SDUI
- [ ] `feat/resilience`: caché, banner offline, panel de debug con Chaos (solo dev), tests de reintento
- [ ] `feat/fx-rates`: micro app con API real + caché + degradación
- [ ] `feat/push`: FCM + deep links
- [ ] `feat/observability`: Crashlytics, Performance, Analytics

### Fase 4 — Calidad y entrega (lunes)
- [ ] `test/e2e`: flujo crítico login → home → cuenta → movimientos (`integration_test`)
- [ ] Revisar cobertura de unit/widget tests en blocs y repositorios
- [ ] `docs/architecture`: diagramas Mermaid (componentes, flujos, dependencias) — _parcial: versión inicial con el diseño planificado (#2); falta reflejar lo implementado_
- [ ] `docs`: ADRs pendientes, `resilience.md`, `deployment-operations.md`, supuestos, riesgos y escalamiento — _parcial: plantilla ADR-000 y estructura de ambos documentos (#2)_
- [ ] README final reproducible — _parcial: estructura (#2)_
- [ ] `docs/ai/AI_USAGE.md` consolidado con métricas de impacto — _parcial: entradas IA-001 e IA-002 (#2)_
- [ ] Video/guion de demo: login, cuentas, cambio de home en vivo vía Remote Config, modo caos, push, fx
- [ ] Release `v1.0.0` + tag + CHANGELOG

### Bonus (solo si hay tiempo)
- [ ] Asistente financiero con IA sobre los movimientos del usuario (detrás de feature flag)
- [ ] Automatizaciones extra (generación de changelog, coverage report en CI) — _parcial: `make coverage` combina el lcov de todos los paquetes en local (#2)_

### Orden de recorte si falta tiempo
1. Asistente IA (bonus)
2. Transferencias (dejar solo lectura)
3. iOS schemes en flavors (dejar solo Android)
4. Analytics detallado

**Nunca recortar:** backend real, SDUI + personalización, resiliencia demostrable, tests (incluido el E2E), documentación de decisiones.

### Log de desvíos
_(Anota aquí cambios de plan con fecha y motivo.)_

- **2026-10-03 · El PR de tooling se dividió en dos.** `chore/tooling-and-docs` se hizo como #1 (`chore/workspace-melos`) y #2 (`chore/tooling-docs`, apilado sobre #1), para que cada PR fuera pequeño y revisable por separado.
- **2026-10-03 · Los plugins de Firebase de cada feature se agregan después.** Auth, Firestore y Messaging se suman en el PR de cada feature y no en el pub workspace (#1), para que cada commit compile sin dependencias nativas que todavía no se usan.
