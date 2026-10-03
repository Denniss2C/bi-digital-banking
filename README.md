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

_Pendiente._

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
