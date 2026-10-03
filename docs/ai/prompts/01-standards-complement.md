# Complemento: estándares de trabajo

- **Fecha:** 2026-10-03
- **Herramienta:** Claude Code (Claude Opus 5.5) en VS Code
- **Uso:** amplía el prompt maestro; agrega a la Fase 1 los pasos (a) tooling y docs y (b) flavors

---

Complemento al prompt maestro. Quiero que el proyecto siga mis estándares de trabajo:

## Stack adicional
- freezed + json_serializable para modelos y estados
- i18n con flutter_localizations + ARB (es por defecto, en)

## Flavors
- dev y prod. Android: productFlavors con applicationId com.dennis.banking_app.dev y com.dennis.banking_app. iOS: schemes equivalentes.
- Entry points main_dev.dart y main_prod.dart con AppConfig por flavor.
- Firebase: un mismo proyecto con una app registrada por flavor (yo correré flutterfire configure por flavor; dime el comando exacto).
- El panel de debug / ChaosInterceptor SOLO disponible en dev.

## Tooling y documentación en la raíz
- Makefile con: setup, bootstrap, gen (build_runner), analyze, format, test, coverage, run-dev, run-prod, build-apk-dev, build-apk-prod
- CHANGELOG.md con formato Keep a Changelog + SemVer; actualízalo en cada PR
- README.md (lo completamos al final, deja la estructura)
- docs/
  - architecture/ (diagramas Mermaid: componentes, flujos, dependencias)
  - adr/ (ADR-000-template.md + los ADR que vayan saliendo)
  - deployment-operations.md
  - resilience.md
  - ai/AI_USAGE.md (bitácora: tarea, herramienta, prompt resumido, qué aceptaste/corregiste, impacto en productividad, calidad, docs y pruebas)
  - ai/prompts/ (guarda aquí este prompt maestro y cada prompt de fase)

## Flujo de Git (Trunk Based Development con ramas cortas)
- .github/pull_request_template.md (qué cambia, por qué, cómo probarlo, checklist: tests, analyze, CHANGELOG, docs)
- .github/CODEOWNERS asignando un "equipo" ficticio por paquete (@team-auth, @team-accounts, etc.) para evidenciar ownership por dominio
- Al inicio de cada paso dime el nombre de la rama (feat/..., chore/..., docs/...); al final, el commit y el título/descripción del PR.
- Commits pequeños con Conventional Commits.

Incorpora esto en la Fase 1: agrega como pasos previos (a) Makefile + docs + templates de GitHub y (b) flavors. Cada entrada que hagamos en AI_USAGE.md debe ser honesta, incluyendo lo que la IA hizo mal y tuve que corregir.
