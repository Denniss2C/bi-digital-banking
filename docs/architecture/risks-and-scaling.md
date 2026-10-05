# Supuestos, riesgos y escalamiento

Qué se dio por hecho, qué puede salir mal y cómo crecería la plataforma.

## Supuestos

| Supuesto | Consecuencia en el diseño |
|----------|---------------------------|
| Plan Spark de Firebase: sin Cloud Functions | La app escribe la apertura de cuentas y las transferencias, protegidas por reglas de seguridad ([ADR-003](../adr/ADR-003-accounts-firestore.md)) |
| Un solo proyecto Firebase para dev y prod, con una app por flavor | Menos configuración para la prueba; las condiciones de Remote Config y los datos se comparten ([ADR-002](../adr/ADR-002-flavors-firebase.md)) |
| Banca 100 % digital en Ecuador, cuentas en USD | Montos en centavos enteros, un solo formato de moneda y textos en español con inglés como segundo idioma |
| No hay core bancario | El historial inicial de cada cliente sale de una plantilla en Firestore (`source: seed`, [ADR-007](../adr/ADR-007-opening-template.md)); lo posterior, como las transferencias, son operaciones reales |
| Las tasas de cambio son de referencia | Tasa media diaria de una API pública, sin compra ni venta inventadas ([ADR-006](../adr/ADR-006-fx-rates-provider.md)) |
| La demo de push es en Android | iOS funciona sin push hasta configurar una clave APNs |
| Escala de prueba técnica | Un desarrollador, CI con GitHub Actions y sin distribución a tiendas |

## Riesgos

| Riesgo | Impacto | Mitigación actual | Siguiente paso |
|--------|---------|-------------------|----------------|
| **Escrituras desde el cliente.** Un cliente modificado podría alterar los saldos de sus propias cuentas | Alto en producción | Las reglas limitan cada usuario a su árbol, validan la forma de los datos, no permiten saldos negativos y hacen inmutable el libro de movimientos | Cloud Functions callable para transferencias y apertura (plan Blaze) y App Check |
| **Dev y prod comparten proyecto.** Una prueba en dev puede afectar datos o configuración de prod | Medio | Flavors con apps distintas; el panel de depuración solo existe en dev | Un proyecto Firebase por entorno |
| **Plantilla de apertura ausente o inválida.** Los clientes nuevos quedarían sin cuentas | Alto | Validación estricta con los límites de las reglas, transacción que no escribe nada a medias, error en Crashlytics y reintento en el próximo login | Alerta sobre ese error y un smoke test después de cada `make deploy-opening` |
| **Layout remoto roto.** Una publicación mala en Remote Config | Medio | La consola valida el JSON, el parser es tolerante, se usa el layout embebido como respaldo, hay un evento `home_layout{source}` y la consola guarda el historial para revertir | Publicar layouts solo desde el repo (`make deploy-rc`), con los tests como puerta |
| **Proveedor de divisas caído o con límite.** Respuestas 429 o sin servicio | Bajo | Reintentos con backoff, caché stale-while-revalidate y aviso offline | Un backend propio que centralice las consultas |
| **Abuso de las claves de cliente de Firebase.** Son públicas por diseño | Medio | Reglas de seguridad y cuotas de Firebase | App Check (Play Integrity y DeviceCheck) y restricción de claves por app |
| **El E2E no corre en CI.** Necesita un dispositivo y un usuario real | Medio | `make e2e` documentado, mensajes de falla explícitos y paso por paso | Emulator Suite con datos efímeros y Firebase Test Lab en CI |
| **Reglas de seguridad sin tests automáticos** | Medio | Compilación al desplegar y revisión en PR | Tests de reglas con el emulador de Firestore |
| **Toolchain al límite.** freezed incompatible y `flutter build ios --simulator` falla con Xcode 27 | Bajo | Sin codegen para modelos y builds de iOS verificados para dispositivo (log de desvíos de `CLAUDE.md`) | Revisar al subir a Dart 3.13 y a una versión nueva de Flutter |
| **Código generado con IA** | Medio | Revisión del autor, tests, mutaciones y una bitácora honesta de errores ([AI_USAGE](../ai/AI_USAGE.md)) | Revisión por pares cuando haya más de un desarrollador |

## Escalamiento

### Equipos y dominios

- **Un paquete por dominio, con dueño en `CODEOWNERS`.** Un equipo nuevo crea su paquete en `packages/features`, que
  depende solo de `core`, `design_system` y `sdui`. El test de reglas obliga a declararlo.
- **El shell es el único punto de integración.** Para sumar un dominio basta con:
  - sus rutas en `createRouter`;
  - su módulo en la inyección de dependencias;
  - sus componentes en `createHomeRegistry`.
- **Contratos en `core`:** `Failure`, `Telemetry` y `KeyValueStore`. Un dominio nuevo reporta y se degrada igual que
  los demás sin conocer Firebase.

### Experiencias sin publicar la app

| Qué cambia | Cómo | Sin versión nueva |
|------------|------|-------------------|
| Orden, contenido y promociones de la home por segmento | Remote Config (`home_layout`) | Sí |
| Encender o apagar funciones | Feature flags de Remote Config | Sí |
| Cuentas e historial de los clientes nuevos | Plantilla en Firestore (`templates/opening`) | Sí |
| Un componente de negocio nuevo | Se agrega al catálogo SDUI. Las versiones viejas lo omiten (forward compatibility) y aparece cuando el servidor lo incluye | Requiere publicar una vez |

**Siguiente paso:** ofertas de apertura y layouts por segmento calculados en el servidor, con audiencias de Analytics
o BigQuery, en lugar de cambiar el segmento desde el panel de depuración.

### Backend y datos

- **Plan Blaze y Cloud Functions:**
  - apertura al crear el usuario, con la misma plantilla;
  - transferencias del lado del servidor;
  - push automático al recibir un movimiento.
- **Un BFF para terceros:** las integraciones con clave (otros proveedores, productos de terceros) van detrás de un
  backend propio, nunca en la app.
- **Firestore escala por cliente:** cada árbol `users/{uid}` es independiente, los movimientos se paginan de 20 en 20 y
  el libro es solo de inserción. Para reportes, exportar a BigQuery.

### Entrega y operación

- **CI hoy:** formato, análisis, tests y código generado al día, con el check obligatorio en `main`.
- **Siguiente paso:**
  - builds firmados y distribución con Firebase App Distribution;
  - el E2E en Test Lab;
  - releases con tags y el CHANGELOG generado.
- **Monitoreo:** los SLOs y las alertas propuestas están en [`deployment-operations.md`](../deployment-operations.md)
  §6. El siguiente paso es automatizar las alertas de Crashlytics (velocidad) y de los eventos de negocio
  (`transfer_failed`, `home_layout{source: fallback}`).
