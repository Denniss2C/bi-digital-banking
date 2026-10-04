# ADR-005: Personalización con Remote Config y el segmento como custom signal

- **Estado:** Aceptado
- **Fecha:** 2026-10-04
- **Autores:** @Denniss2C
- **Equipos afectados:** @team-platform, @team-sdui, @team-accounts

## Problema

La home debe **cambiar según el perfil del cliente** (nuevo, ahorrador, viajero…) y el negocio debe poder cambiarla,
y apagar funciones, **sin publicar una versión**. El motor SDUI (ADR-004) ya sabe dibujar un layout; falta decidir de
dónde sale cada layout, cómo se elige por cliente y cómo llega a la app.

## Alternativas

| Alternativa | A favor | En contra |
|-------------|---------|-----------|
| A. **Remote Config con el segmento como _custom signal_** | Las condiciones se evalúan en el servidor y la consola sirve para operar en vivo. Trae caché, valores por defecto y actualizaciones en tiempo real. No necesita Analytics ni backend propio. | El segmento lo envía el cliente. Los layouts JSON se editan como texto. |
| B. Remote Config con **propiedades de usuario de Analytics** | Es la segmentación clásica de Remote Config. | Depende de Analytics y las propiedades tardan en propagarse; la demo no sería inmediata. |
| C. Layouts en **Firestore** (`layouts/{screenId}`) elegidos en la app | Mismo backend que los datos y tiempo real. | La lógica de qué layout corresponde a cada segmento queda en la app; no hay consola de operación ni versiones con rollback. |
| D. Reglas en la app (if por segmento) | Simple. | Cada cambio exige publicar la app, que es justo lo que se quiere evitar. |

## Decisión

**Alternativa A.**
- **Parámetros:** `home_layout` (JSON), con un valor por defecto y uno por segmento, más los flags
  `feature_transfers_enabled`, `feature_fx_enabled` y `feature_ai_assistant_enabled`.
- **Segmento:** sale de `users/{uid}.segment` (`new_user` al abrir la cuenta). La app lo envía con `setCustomSignals`
  y pide valores en el momento. Las condiciones son
  `app.customSignal['segment'].exactlyMatches(['saver'])` y lo mismo para `traveler`.
- **Valores por defecto en la app:** los mismos que en la plantilla, incluido el layout embebido. Con la app sin
  conexión, o con un JSON roto, la home sigue funcionando.
- **Tiempo real:** al publicar en la consola, la app activa los valores nuevos sin reiniciar.
- **Plantilla versionada:** está en `firebase/remoteconfig.template.json` y se genera desde
  `firebase/remote-config/*.json` (`make rc-template`). Los tests verifican que esté al día y que cada layout sea válido.
  Se publica con `make deploy-rc`.

## Trade-offs

- **El segmento lo controla el cliente.** Un cliente modificado podría pedir el layout de otro segmento. No expone
  datos (los layouts no son secretos ni personales), pero en producción el segmento lo asignaría un proceso del
  servidor y la app solo lo leería. Mientras tanto, las reglas de Firestore permiten que cada usuario edite su propio
  perfil.
- **Editar JSON dentro de la consola es frágil.** Lo cubren el parser tolerante y el fallback (ADR-004), además de los
  tests de la plantilla para lo que pasa por el repo.
- **Dos fuentes del layout por defecto** (la constante embebida y el archivo de la plantilla). Un test falla si dejan
  de coincidir.
- **Cuotas de Remote Config.** En prod se pide como mucho una vez por hora (más el tiempo real y los cambios de
  segmento); en dev, en cada pull to refresh.

## Impacto a largo plazo

- **Otras pantallas** pueden seguir el mismo patrón: un parámetro por pantalla y los mismos segmentos.
- **Segmentación real:** un job del servidor (o una Cloud Function con plan Blaze) asignaría `segment` según el
  comportamiento del cliente, sin cambiar la app.
- **Experimentos:** Remote Config permite A/B testing sobre los mismos parámetros cuando haya Analytics
  (`feat/observability`).
