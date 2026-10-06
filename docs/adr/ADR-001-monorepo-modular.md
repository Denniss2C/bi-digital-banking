# ADR-001: Monorepo modular con Melos y pub workspaces

- **Estado:** Aceptado
- **Fecha:** 2026-10-03
- **Autores:** @Denniss2C
- **Equipos afectados:** todos (@team-platform, @team-design-system, @team-sdui, @team-auth, @team-accounts,
  @team-notifications, @team-fx)

## Problema

La plataforma debe crecer hacia **varios dominios mantenidos por equipos independientes** (autenticación, cuentas,
notificaciones, divisas…) que comparten infraestructura (red resiliente, design system, motor SDUI) sin acoplarse
entre sí. La estructura del código tiene que:

- hacer **explícitas y verificables** las fronteras entre dominios;
- permitir que cada equipo trabaje, analice y pruebe su parte por separado;
- mantener **una sola app** publicada y un solo flujo de entrega (Trunk Based Development);
- poder operarse con una persona en tres días y escalar a varios equipos después.

## Alternativas

| Alternativa | A favor | En contra |
|-------------|---------|-----------|
| A. **App única**, con carpetas por feature | Es lo más simple; no necesita tooling extra y los refactors son fáciles. | Las fronteras dependen solo de la convención: nada impide que `accounts` importe el código interno de `auth`. El análisis y los tests son siempre de todo, y el ownership queda difuso. |
| B. **Monorepo modular**: un paquete Dart por dominio + pub workspaces + Melos | **El compilador hace cumplir las fronteras**: un feature solo ve lo que declara en su `pubspec`. Hay un solo lockfile, los cambios entre paquetes son atómicos en un PR, CODEOWNERS puede ir por carpeta, y hay scripts comunes y una sola CI. | Exige más estructura (un `pubspec` por paquete, exports explícitos, DI entre paquetes). El shell tiene que componer rutas y dependencias. Melos y pub workspaces son tooling adicional que hay que dominar. |
| C. **Repos separados** por dominio, con paquetes versionados por git o pub privado | Independencia total de los equipos: releases, permisos y CI propios. | Un cambio transversal exige PRs coordinados en N repos y publicar versiones. Las dependencias divergen entre repos. Es mucha operación para un equipo chico y no es viable en tres días. |

## Decisión

**Monorepo modular (alternativa B)** con **Dart pub workspaces** y **Melos 8**, configurado en el `pubspec.yaml` raíz
(sin `melos.yaml`):

```text
apps/banking_app                  shell: composición, routing, DI global, flavors
packages/core                     red resiliente, errores tipados, infraestructura
packages/design_system            tokens, temas y componentes accesibles
packages/sdui                     motor Server-Driven UI
packages/features/{auth,accounts,notifications,fx_rates}   dominios
```

**Regla de dependencias:** los features dependen solo de `core`, `design_system` y `sdui`, nunca entre sí. La
comunicación entre features pasa por el shell (rutas y contratos definidos en `core`).

## Trade-offs

- **Más estructura por feature.** Cada uno tiene su propio `pubspec`, sus exports y una DI que compone el shell. Se
  acepta porque convierte las fronteras en errores de compilación en lugar de convenciones.
- **Un solo lockfile.** Todos los paquetes comparten las versiones de sus dependencias. Simplifica, pero un equipo no
  puede actualizar una dependencia sin comprobar que no rompe a los demás; por eso CI verifica todo el monorepo en
  cada PR.
- **Tooling que cambia.** Melos 8 cambió su configuración: los scripts van en `pubspec.yaml`, y `run` y `exec` ya no
  se combinan (ver AI_USAGE IA-001). Se mitiga con el **Makefile como fachada estable**, que usan tanto las personas
  como CI.
- **CI corre todo.** Con 8 paquetes, un run completo tarda unos 7 minutos (6 min 46 s el primero, sin caché), y casi la
  mitad es la verificación del código generado. Con más paquetes, se puede limitar la ejecución a los paquetes
  afectados (filtros de Melos por diff).
- **La regla "un feature no depende de otro"** hoy se cuida en la revisión (CODEOWNERS) y se ve en el grafo de
  `pubspec`. _Planificado:_ un chequeo automático en CI.

## Impacto a largo plazo

- **Escala de equipos.** Cada dominio es un paquete con dueño. Un equipo nuevo agrega
  `packages/features/<dominio>` sin tocar a los demás.
- **Camino a repos separados.** Un feature ya empaquetado se puede extraer a su propio repo y publicar si un equipo
  necesita releases independientes. La alternativa C queda abierta sin reescribir código.
- **Señales para reconsiderar:** que los dominios necesiten ciclos de release distintos, o que la CI del monorepo
  completo supere los ~15 minutos.

## Actualizaciones

- **2026-10-04:** el chequeo automático de la regla "un feature no depende de otro" ya existe. Un test lee los
  `pubspec.yaml` del workspace y falla si un paquete declara uno interno que su regla no permite
  ([reglas](../architecture/dependencies.md#reglas)).
- **2026-10-05:** cada paquete declara solo lo que importa, y build_runner corre solo en el shell, el único paquete con
  anotaciones de injectable. El paso de CI que verifica el código generado deja de compilar builders en 6 paquetes.
