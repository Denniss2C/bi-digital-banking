# Nexo Banco Digital

[![CI](https://github.com/Denniss2C/bi-digital-banking/actions/workflows/ci.yml/badge.svg)](https://github.com/Denniss2C/bi-digital-banking/actions/workflows/ci.yml)

Plataforma financiera 100% digital en Flutter para Ecuador, con la marca ficticia **Nexo**. Es una prueba técnica
para Banco Internacional (Ecuador). La identidad visual está en [`docs/design/`](docs/design/DESIGN.md).

> 🚧 Documento en construcción: se completa al cierre de la Fase final.

## Tabla de contenidos

1. [Visión general](#visión-general)
2. [Arquitectura](#arquitectura)
3. [Estructura del monorepo](#estructura-del-monorepo)
4. [Requisitos previos](#requisitos-previos)
5. [Puesta en marcha](#puesta-en-marcha)
6. [Flavors y configuración](#flavors-y-configuración)
7. [Comandos de desarrollo](#comandos-de-desarrollo)
8. [Pruebas y cobertura](#pruebas-y-cobertura)
9. [Resiliencia y modo caos](#resiliencia-y-modo-caos)
10. [Personalización y Server-Driven UI](#personalización-y-server-driven-ui)
11. [Flujo de trabajo (Trunk Based Development)](#flujo-de-trabajo-trunk-based-development)
12. [Decisiones de arquitectura (ADR)](#decisiones-de-arquitectura-adr)
13. [Uso de IA](#uso-de-ia)

## Visión general

_Pendiente._

## Arquitectura

Ver [docs/architecture](docs/architecture/README.md).

## Estructura del monorepo

```text
apps/banking_app                -> shell: composición, routing, DI global
packages/core                   -> network, errores, logger, connectivity, caché
packages/design_system          -> tokens, tema claro/oscuro, componentes accesibles
packages/sdui                   -> motor Server-Driven UI
packages/features/auth          -> onboarding, registro, login
packages/features/accounts      -> cuentas, saldos, movimientos, transferencias
packages/features/notifications -> FCM
packages/features/fx_rates      -> micro app de tipo de cambio (API pública)
```

## Requisitos previos

_Pendiente: versión de Flutter, Dart, FlutterFire CLI, Xcode / Android Studio._

## Puesta en marcha

```bash
make setup
make run-dev
```

## Flavors y configuración

_Pendiente._ Ver [docs/deployment-operations.md](docs/deployment-operations.md).

## Comandos de desarrollo

Ejecuta `make help` para ver todos los comandos disponibles.

## Pruebas y cobertura

| Tipo | Dónde | Cómo correrlas |
|------|-------|----------------|
| Unitarias y de widgets | `test/` de cada paquete: blocs, repositorios, casos de uso, componentes y pantallas | `make test`; cobertura combinada con `make coverage` |
| E2E del flujo crítico | `apps/banking_app/integration_test/critical_flow_test.dart` | `make e2e` en un emulador o dispositivo (`DEVICE=<id>` si hay varios) |

**E2E.** Recorre login → Inicio → Cuentas → Cuenta de Ahorros → movimientos (dos páginas de Firestore) → logout, contra
el Firebase **real** del flavor dev. Necesita un usuario de prueba:

1. Regístralo una vez desde la app (`make run-dev` → Crear cuenta), por ejemplo `e2e@nexo.test`.
2. Copia `apps/banking_app/e2e.env.example.json` a `apps/banking_app/e2e.env.json` (git lo ignora) y completa su
   correo y su contraseña.
3. Corre `make e2e`.

- **Qué escribe:** solo lee datos. Lo único que escribe es la apertura de cuentas en el primer login del usuario y el
  token de push, que se borra al cerrar sesión.
- **Qué verifica:** la estructura (dos cuentas y los movimientos hasta el depósito de apertura), no saldos exactos.
- **Efecto en el dispositivo:** usa la app dev instalada y termina con la sesión cerrada.
- **Fuera del CI:** necesita un dispositivo y credenciales. El paso siguiente sería correrlo contra el Emulator Suite de
  Firebase, con datos efímeros.

## Resiliencia y modo caos

Ver [docs/resilience.md](docs/resilience.md).

## Personalización y Server-Driven UI

_Pendiente._

## Flujo de trabajo (Trunk Based Development)

_Pendiente: ramas cortas, Conventional Commits, PR template, CODEOWNERS._

## Decisiones de arquitectura (ADR)

Ver [docs/adr](docs/adr/).

## Uso de IA

Ver [docs/ai/AI_USAGE.md](docs/ai/AI_USAGE.md).
