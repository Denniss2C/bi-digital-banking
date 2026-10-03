# Prompt maestro

- **Fecha:** 2026-10-03
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code
- **Uso:** contexto inicial del proyecto y tarea de la Fase 1

---

Actúa como Senior Flutter Architect. Estoy construyendo una prueba técnica para Banco Internacional (Ecuador): una plataforma financiera digital en Flutter, entrega el lunes en la noche. Trabajamos con Trunk Based Development: cambios pequeños, cada paso debe compilar y ser commiteable a main.

## Objetivo del reto
Plataforma financiera 100% digital, modular (dominios mantenidos por equipos independientes), con experiencia personalizada según perfil/comportamiento y capacidad de cambiar UI/contenido SIN publicar nueva versión. No se aceptan solo datos simulados: debe haber interacción real con servicios.

## Stack obligatorio
- Flutter estable, Dart 3, null safety
- Monorepo con Melos 8.x + Dart pub workspaces
- Estado: flutter_bloc (Bloc/Cubit) + equatable
- Arquitectura: Clean Architecture por feature (data / domain / presentation)
- DI: get_it + injectable
- Navegación: go_router
- Backend: Firebase (Auth, Cloud Firestore, Cloud Messaging, Remote Config, Crashlytics, Performance)
- HTTP para APIs externas: dio con interceptores
- Caché local: hive_ce
- Errores: Either de fpdart, Failures tipadas (NetworkFailure, ServerFailure, CacheFailure, AuthFailure)
- Tests: bloc_test, mocktail, flutter_test, integration_test

## Estructura
/apps/banking_app                -> shell: composición, routing, DI global
/packages/core                   -> network (dio + RetryInterceptor + ChaosInterceptor), errores, logger, connectivity
/packages/design_system          -> tokens, tema claro/oscuro, componentes accesibles
/packages/sdui                   -> motor Server-Driven UI: JSON -> registro de widgets -> render
/packages/features/auth          -> onboarding, registro, login
/packages/features/accounts      -> cuentas, saldos, movimientos, transferencias
/packages/features/notifications -> FCM
/packages/features/fx_rates      -> micro app externa (tipo de cambio, API pública real)

Reglas: los features NO dependen entre sí; solo de core, design_system y sdui. La comunicación entre features pasa por el shell.

## Requisitos transversales
- Toda pantalla con estados: loading, success, empty, error (con reintento), offline (datos en caché + aviso)
- RetryInterceptor: backoff exponencial con jitter, máx. 3 intentos, solo errores transitorios
- ChaosInterceptor activable desde un panel de debug: latencia, % de fallos, modo sin red
- Firestore con persistencia offline habilitada
- Accesibilidad: Semantics, contraste, texto escalable
- Sin secretos en el código

## Forma de trabajar
- Antes de implementar, analiza y propón el diseño en 5-10 líneas; luego implementa.
- Archivos completos con su ruta.
- Tests para la lógica que generes.
- Al final de cada paso, sugiere un mensaje de commit (Conventional Commits).
- Si hay una decisión de arquitectura, redacta un ADR corto: Problema, Alternativas, Decisión, Trade-offs, Impacto a largo plazo (en docs/adr/).
- Código y comentarios en inglés; documentación en español.

## Tarea actual
Fase 1 – Base (el scaffolding ya existe: apps/banking_app y packages/* creados con flutter create, Firebase configurado con flutterfire, primer commit en main).

IMPORTANTE: uso Melos 8.x. NO crees melos.yaml. La configuración va en un pubspec.yaml en la raíz con pub workspaces:
- Raíz: name: bi_digital_banking_workspace, publish_to: none, environment sdk ^3.6.0, sección `workspace:` listando todos los paquetes, y sección `melos:` con los scripts.
- Cada paquete y la app: agregar `resolution: workspace` en su pubspec.

Pasos:
1. pubspec.yaml raíz con workspace + scripts melos: analyze, test, format, build_runner. Ajusta los pubspec con sus dependencias.
2. core: cliente dio con RetryInterceptor y ChaosInterceptor configurable en runtime, con tests unitarios.
3. design_system: AppTheme claro/oscuro con tokens y componentes AppButton, AppCard, AppErrorView(onRetry), AppLoading.
4. banking_app: main con Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform), get_it, go_router con rutas /splash, /login, /home (placeholders).
5. .github/workflows/ci.yml: setup Flutter, activar melos, melos bootstrap, melos run analyze, melos run test en push a main.
6. ADR-001 en docs/adr/: Monorepo modular con Melos vs app única vs repos separados.

Haz UN paso por vez, sugiere el commit al final de cada uno y espera mi confirmación antes de seguir.
