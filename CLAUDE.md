# CLAUDE.md — Contexto del proyecto `bi-digital-banking`

> Este archivo es la fuente de verdad para el asistente de IA que trabaja en este repo.
> Léelo completo al inicio de cada sesión. Mantén actualizada la sección **Roadmap** (marca `[x]` al terminar cada ítem y anota desvíos).

---

## 1. Qué es este proyecto

Prueba técnica para el puesto **Mobile Flutter Senior Developer** en **Banco Internacional (Ecuador)**.

**Producto:** **Nexo Banco Digital** ("nexo"), una marca ficticia de banca 100% digital para Ecuador (cuentas en USD).
La identidad visual está en `docs/design/` (ver §4, *Producto y diseño visual*). Los identificadores técnicos no
cambian: `banking_app`, `com.dennis.banking_app` y el repo `bi-digital-banking`.

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
docs/                            -> architecture/, adr/, ai/, design/, deployment-operations.md, resilience.md
```

**Reglas de dependencia:** los features NO dependen entre sí; solo de `core`, `design_system` y `sdui`. La comunicación entre features pasa por el shell (rutas y contratos definidos en `core`).

## 4. Diseño de referencia (ajustable, documentar cambios en ADR)

### Producto y diseño visual — Nexo Banco Digital
**Fuente de verdad visual:** `docs/design/DESIGN.md` (tokens y guía, generados con Stitch) y `docs/design/screens/`.
Toda UI nueva parte de ahí; si algo se aparta del diseño, se anota en el log de desvíos.

- **Nombres visibles:** "Nexo" (prod) y "Nexo Dev" (dev).
- **Color:**
  - primario naranja `#F28C28` (CTAs, foco y acentos) y secundario navy `#1B2A41` (estructura, tarjetas hero, navegación);
  - fondo `#F8FAFC`, superficies `#FFFFFF`, bordes `#E2E8F0`, texto `#0F172A` y texto secundario `#64748B`.
- **Tipografía:** Inter, empaquetada en `design_system` (sin descarga en runtime), con cifras tabulares en todos los montos.
- **Forma y espacio:**
  - grilla de 8 pt, márgenes de 16 px y áreas táctiles de al menos 48 px;
  - radios de 16 px (tarjetas), 12 px (botones) y pill (chips y acciones rápidas);
  - elevación en 3 niveles, más la tarjeta hero navy.
- **Tema oscuro:** `DESIGN.md` solo define el claro. El oscuro se deriva de los mismos tokens (navy como superficie)
  y se documenta en `design_system`.
- **Accesibilidad (decisiones que corrigen el diseño original, que no cumple WCAG AA en estos puntos):**
  - Texto sobre naranja: **navy `#1B2A41`** (5.88:1), no blanco (2.45:1). Las pantallas de Stitch usan blanco.
  - Montos positivos: texto **`#006C49`** (6.48:1). El verde `#10B981` (2.54:1) solo como relleno decorativo.
  - Montos negativos y errores: texto **`#BA1A1A`** (6.46:1). El rojo `#EF4444` (3.76:1) solo en íconos o fondos.
  - Todo componente con `Semantics`, y la UI soporta texto escalado sin cortes.
- **Navegación:** barra inferior con 4 pestañas (**Inicio, Cuentas, Divisas, Perfil**), implementada con
  `StatefulShellRoute` de go_router. En **Perfil** van el logout y, solo en dev, la entrada al panel de debug.
- **Pantallas → features y alcance.** Los datos de las pantallas (Mateo, saldos, contactos) son ilustrativos; la app
  usa datos reales de Firebase.

| Pantalla (`docs/design/screens/`) | Feature | Dentro del alcance | Fuera del alcance (documentado) |
|---|---|---|---|
| `onboarding_*` | auth | 3 slides (Banca, Seguridad, Ahorro), Omitir y Continuar | — |
| `autenticaci_n_*` | auth | login y registro con email y contraseña (Firebase Auth), recuperar contraseña | login con cédula/RUC, biometría (bonus) |
| `inicio_*` | shell + sdui | home por SDUI: `balance_card`, `quick_actions`, `promo_banner`, `fx_widget`, `tx_list` | acciones Servicios, Cajero y "De Una QR" |
| `cuentas_y_tarjetas_*` | accounts | cuentas, saldos y movimientos | tarjeta virtual, metas de ahorro, datos SPI |
| `transferir_dinero_*` | accounts | transferencia entre cuentas propias ("A cuentas Nexo"), montos rápidos y concepto | SPI interbancaria, internacional, contactos, biometría |
| `divisas_y_remesas_*` | fx_rates | cotizador con tasas reales y caché | monederos multidivisa, remesas, mapa de canales |
| `logo_*` | shell | ícono y splash | — |

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
- El diseño muestra compra/venta ("C:" / "V:"), pero la API entrega una tasa media. Se muestra la tasa real con
  "actualizado hace X" y **no se inventan spreads** (serían datos simulados).

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
- [x] `feat/flavors`: dev/prod (Android productFlavors + iOS schemes), `main_dev.dart`/`main_prod.dart`, `AppConfig`, Firebase por flavor
  - Nota: el bundle ID de iOS es `com.dennis.bankingApp` porque iOS no admite `_`; el de dev es `com.dennis.bankingApp.dev`.
  - Detalle y comandos de flutterfire en `docs/deployment-operations.md`; decisión en ADR-002.
- [x] `feat/core-network`: cliente dio + RetryInterceptor + ChaosInterceptor + tests
  - 3 intentos en total (1 + 2 reintentos); el caos rechaza con `reject(error, true)` para que lo vea el retry. Detalle en `docs/resilience.md`.
- [x] `feat/design-system`: tema claro/oscuro, tokens, AppButton, AppCard, AppErrorView(onRetry), AppLoading
  - Tokens y reglas de contraste de §4 *Producto y diseño visual*; Inter empaquetada; tema oscuro derivado.
  - Además: `AppEmptyView` y `AppSemanticColors`. Uso y reglas en `packages/design_system/README.md`.
- [x] `feat/app-shell`: Firebase init, get_it/injectable, go_router (/splash, /login, /home), i18n es/en
  - `/home` con la barra inferior del diseño (Inicio, Cuentas, Divisas, Perfil) como `StatefulShellRoute`; pestañas placeholder.
  - Entorno de injectable = flavor: `@dev` registra solo en dev. Si el idioma del dispositivo no está soportado, se usa español.
  - Código generado **versionado** (`lib/di/injection.config.dart`, `lib/l10n/gen/`); se regenera con `make gen` y `flutter gen-l10n`.
- [x] `ci/github-actions`: analyze + test en push y PR → luego marcar el check como obligatorio en `main`
  - Además verifica formato y código generado. El check `Analyze, format and test` es obligatorio en `main` desde el 2026-10-03.
- [x] `docs/adr-001`: monorepo modular (Melos) vs app única vs repos separados
  - **Fase 1 completa** el 2026-10-03 a las 15:40 (meta: 17:00).

### Fase 2 — Núcleo funcional (sábado noche)
- [x] `feat/auth`: onboarding (2-3 pantallas), registro, login, sesión persistente, logout, redirect con go_router
  - Partido en dos PRs: `feat/auth-data` (dominio y datos) y `feat/auth-ui` (cubits, pantallas, redirect y textos del feature).
  - Pantallas `onboarding_*` y `autenticaci_n_*`: email y contraseña; login con cédula y biometría quedan fuera.
- [x] `feat/accounts-data`: modelo Firestore, seed al registrarse, reglas de seguridad
  - Dinero en centavos (`balanceCents`, `amountCents`). Apertura idempotente desde el shell al iniciar sesión. Reglas desplegadas el 2026-10-03; ver ADR-003.
- [x] `feat/accounts-ui`: lista de cuentas, saldo, movimientos (paginados) con todos los estados
  - Pantalla `cuentas_y_tarjetas_*`: solo cuentas y movimientos (tarjeta virtual y metas quedan fuera).
- [x] `feat/transfers`: transferencia entre cuentas propias (`runTransaction`) — **recortable**
  - Pantalla `transferir_dinero_*`, opción "A cuentas Nexo" (otros bancos, contactos y biometría quedan fuera).
  - Idempotente con `transferId`, que es el id de documento de los dos movimientos. Límite demo de $5,000.00 por transferencia. Necesita conexión: las transacciones de Firestore no funcionan offline.

### Fase 3 — Diferenciadores (domingo)
- [x] `feat/sdui-engine`: parser + registry + render + fallback + tests
  - Contrato con `schemaVersion` e `id` opcional (README de `sdui`); decisión en ADR-004. Componentes estándar `promo_banner` y `quick_actions`; los que usan datos (`balance_card`, `tx_list`, `fx_widget`) los registra cada feature.
- [x] `feat/personalization`: Remote Config por segmento + feature flags; home renderizada por SDUI
  - La home por defecto replica la pantalla `inicio_*`; cada segmento cambia el orden, la promo o los componentes.
  - Partido en dos PRs (decisión del autor, 2026-10-04): `feat/home-sdui` (home por SDUI con el layout embebido; accounts aporta `balance_card` y `tx_list`) y `feat/remote-personalization` (Remote Config con el segmento como custom signal, flags, actualización en vivo y plantilla versionada desplegada con la CLI).
  - Plantilla publicada el 2026-10-04 (`make deploy-rc`). Decisión en ADR-005; operación en `docs/deployment-operations.md` §7. `feature_fx_enabled` se aplica en `feat/fx-rates`.
- [x] `feat/resilience`: caché, banner offline, panel de debug con Chaos (solo dev), tests de reintento
  - Corregido el pendiente de `feat/transfers`: `SignInCubit`, `SignUpCubit` y `TransactionsCubit` descartan la respuesta si la pantalla ya se cerró.
  - Panel de depuración (solo dev): caos HTTP, Firestore sin red, segmento del cliente y Remote Config. Guion de demo en `docs/resilience.md` §6.
  - El aviso offline sale de `isFromCache` de Firestore; se descartó `connectivity_plus` (ver `docs/resilience.md` §5). El caos HTTP se ve desde `feat/fx-rates`, que es la primera llamada con dio.
- [x] `feat/fx-rates`: micro app con API real + caché + degradación
  - Pantalla `divisas_y_remesas_*`: cotizador; tasa media real, sin spreads inventados.
  - ExchangeRate-API (acceso abierto, sin clave, con atribución) y caché stale-while-revalidate en `hive_ce`; decisión en ADR-006. `fx_widget` en la home y `feature_fx_enabled` aplicado. Plantilla de Remote Config republicada (el widget abre Divisas).
- [x] `feat/push`: FCM + deep links
  - Paquete `notifications` sin UI y `PushCoordinator` en el shell. Las rutas de los mensajes se validan como las acciones SDUI. Token en `users/{uid}.fcmTokens` (se quita al cerrar sesión). Demo en Android con "Enviar mensaje de prueba" y el token del panel de depuración; iOS sin APNs (documentado en `deployment-operations.md` §7).
- [x] `feat/observability`: Crashlytics, Performance, Analytics
  - Interfaz `Telemetry` en `core` y `FirebaseTelemetry` en el shell; eventos sin datos personales. SLOs, alertas y detección de problemas de UX en `docs/deployment-operations.md` §6. Plugin de Gradle de Crashlytics 3.0.8 (AGP 9).
  - **Fase 3 completa** el 2026-10-04.

### Fase 4 — Calidad y entrega (adelantada al domingo; el lunes queda para grabar y corregir)
- [x] `feat/app-icon`: ícono de la app y splash con el logo del diseño (`logo_*`), pedido por el autor el 2026-10-04
  - `NexoLogo` vectorial en `design_system`; `make brand-assets` genera los PNG de Android e iOS con el mismo painter. Detalle en `docs/deployment-operations.md` §4.
- [x] `test/e2e`: flujo crítico login → home → cuenta → movimientos (`integration_test`)
  - Contra el Firebase real de dev, con un usuario de prueba creado por el autor (credenciales en `apps/banking_app/e2e.env.json`, ignorado por git). `make e2e` en un emulador o dispositivo; no corre en CI. Siguiente paso posible: Emulator Suite. Pasó el 2026-10-04 en 6 s.
- [ ] Revisar cobertura de unit/widget tests en blocs y repositorios
- [ ] `docs/architecture`: diagramas Mermaid (componentes, flujos, dependencias) — _parcial: versión inicial con el diseño planificado (#2); falta reflejar lo implementado_
- [ ] `docs`: ADRs pendientes, `resilience.md`, `deployment-operations.md`, supuestos, riesgos y escalamiento — _parcial: plantilla ADR-000 y estructura de ambos documentos (#2)_
- [ ] README final reproducible — _parcial: estructura (#2). Pendiente también: el README de `core` sigue siendo la plantilla de `flutter create`._
- [ ] `docs/ai/AI_USAGE.md` consolidado con métricas de impacto — _parcial: entradas IA-001 a IA-024_
- [ ] Video/guion de demo: login, cuentas, cambio de home en vivo vía Remote Config, modo caos, push, fx — _parcial: guion con 15 escenarios, video sugerido y preguntas en vivo en `docs/demo/guion-demo.md` (#25); falta grabar_
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
- **2026-10-03 · iOS sin CocoaPods.** Flutter 3.44 resuelve todos los plugins con Swift Package Manager; el proyecto no tiene `Podfile`.
- **2026-10-03 · `flutter build ios --simulator` no funciona con Xcode 27** (incompatibilidad de `lipo` con Flutter 3.44.7). iOS se verifica con builds de dispositivo sin firma o con `flutter run` sobre un simulador concreto. Ver `docs/deployment-operations.md`.
- **2026-10-03 · Una sola sesión de IA por carpeta.** Dos sesiones en la misma carpeta compartían rama e índice, y cambios de `feat/flavors` terminaron en el primer commit de `docs/design-reference`. Ese commit se rehízo limpio desde `main`. Regla: una sola sesión trabaja en la carpeta del repo; si hace falta otra en paralelo, va en su propio worktree (`../bi-digital-banking-<tema>`).
- **2026-10-03 · Modelo de datos en centavos y `equatable` 2.x.** Los campos del modelo de §4 pasan a `balanceCents` y `amountCents` (enteros) y suman `source` (`seed` o `transfer`). `equatable` baja a 2.x porque `fake_cloud_firestore`, que se usa para testear Firestore, lo exige. Tampoco se usa json_serializable: el mapeo es manual, igual que la decisión sobre freezed.
- **2026-10-03 · Sin freezed (decisión del autor).** freezed estable no es compatible con el toolchain: la 3.2.5 exige `analyzer <11`, `injectable_generator` exige `>=11` y freezed 4 exige Dart 3.13 (tenemos 3.12). Los estados y modelos usan clases `sealed` + equatable con `copyWith` escrito a mano, sin codegen ni prereleases. Revisar al subir a Dart 3.13.
- **2026-10-03 · Transferencias idempotentes (fuera del plan).** Firestore reintenta una transacción si se pierde la respuesta del commit, aunque el servidor ya la haya aplicado, y el usuario puede reintentar tras un error de red: sin protección, una transferencia podía cobrarse dos veces. Se agregó una clave de idempotencia (`transferId`) que el formulario reutiliza en cada reintento. Costó unos 25 minutos más de lo estimado.
- **2026-10-03 · Referencia de diseño "Nexo Digital".** Se sumó `docs/design/` (Stitch) como fuente del design system. La app adopta la marca: los nombres visibles pasan de "BI Banca" / "BI Dev" a "Nexo" / "Nexo Dev" (`docs/align-design`). Se corrigen tres contrastes del diseño que no cumplen AA (ver §4).
- **2026-10-04 · Fase 4 adelantada al domingo (decisión del autor).** Toda la Fase 4 (guion, arquitectura, README, E2E, cobertura y release) se hace el domingo; el lunes queda para grabar los videos y corregir lo que aparezca en la prueba general.
- **2026-10-04 · Ícono y splash con un generador propio.** `flutter_launcher_icons` 0.14 choca con Melos 8 por `cli_util`, y sus versiones viejas bajaban `xml` en todo el workspace y volvían a CocoaPods. El generador es un script propio que dibuja con `NexoLogo`; los XML de Android y el storyboard de iOS se escribieron a mano.
- **2026-10-04 · Marca centrada en el ícono (desvío del diseño).** En la imagen de Stitch la marca está corrida a la derecha (cerca del 5 %); en el ícono y en la app va centrada, porque descentrada se nota en las máscaras redondas de Android.
