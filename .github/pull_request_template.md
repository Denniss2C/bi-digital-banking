## ¿Qué cambia?

<!-- Resumen en 1-3 líneas de lo que introduce este PR. -->

## ¿Por qué?

<!-- Problema o requisito que resuelve. Enlaza el ADR o el issue si existe. -->

## ¿Cómo probarlo?

<!-- Pasos concretos y reproducibles: comandos, flavor, pantallas, escenarios del modo caos. -->

```bash
make bootstrap
make analyze
make test
```

## Evidencia

<!-- Opcional: capturas, video, salida de comandos o reporte de cobertura. -->

## Tipo de cambio

- [ ] `feat` — nueva funcionalidad
- [ ] `fix` — corrección de un bug
- [ ] `refactor` — sin cambio de comportamiento
- [ ] `test` — solo pruebas
- [ ] `docs` — solo documentación
- [ ] `build` / `ci` / `chore` — tooling, dependencias o pipeline

## Checklist

- [ ] La rama es corta, sale de `main` y sigue el formato `tipo/descripcion` (`feat/…`, `fix/…`, `chore/…`, `docs/…`, `ci/…`)
- [ ] Los commits siguen Conventional Commits
- [ ] `make analyze` no reporta issues
- [ ] `make format-check` no requiere cambios
- [ ] `make test` pasa y la lógica nueva tiene tests
- [ ] `CHANGELOG.md` actualizado en `[Unreleased]`
- [ ] Documentación actualizada (`docs/`, README) y ADR si hay una decisión de arquitectura
- [ ] Entrada en `docs/ai/AI_USAGE.md` si se usó IA
- [ ] Sin secretos ni credenciales en el código
- [ ] Si hay UI: Semantics, contraste y texto escalable revisados
- [ ] Ningún feature depende de otro feature
