# ADR-007: Plantilla de apertura de cuentas en Firestore

- **Estado:** Aceptado. Reemplaza la parte de [ADR-003](ADR-003-accounts-firestore.md) sobre los datos de apertura.
- **Fecha:** 2026-10-04
- **Autores:** @Denniss2C
- **Equipos afectados:** @team-accounts, @team-platform

## Problema

Cada cliente nuevo recibe dos cuentas con su historial inicial de movimientos. Sus saldos y movimientos se leen y
escriben en Firestore, pero la **plantilla** con la que se abren estaba escrita en el código de la app
(`opening_data.dart`). Eso tenía tres problemas:

- **Parecía data quemada:** era lo único que salía del código, y la prueba descarta los datos estáticos.
- **Cambiar la oferta de apertura** (otra cuenta, otro saldo inicial) obligaba a publicar una versión nueva, en contra
  del objetivo de la plataforma.
- **Se mezclaba código con contenido:** la plantilla es contenido de negocio, no lógica.

## Alternativas

| Alternativa | A favor | En contra |
|-------------|---------|-----------|
| A. Seguir en el código | Sin trabajo. | Los tres problemas de arriba. |
| B. **Documento en Firestore** (`templates/opening`), publicado desde el repo con `gcloud` | Datos en el backend, editables desde la consola sin publicar la app. Las reglas lo dejan de solo lectura para los clientes. | Hay que publicarlo antes de que entre un cliente nuevo; requiere `gcloud` para hacerlo desde el repo. |
| C. Remote Config | Ya se publica con la CLI de Firebase. | No es un almacén de datos de negocio, y el autor pidió que los valores vivan en Firestore. |
| D. Cloud Function `onUserCreate` | La apertura ocurre en el servidor. | Necesita el plan Blaze. |

## Decisión

**Alternativa B.**

- **Fuente:** `firebase/opening-template.json`, revisable en un PR. `make deploy-opening` lo publica en
  `templates/opening` con la API REST de Firestore y el token de `gcloud auth print-access-token`.
- **Lectura:** en el primer inicio de sesión de un cliente, la app lee la plantilla dentro de la misma transacción
  idempotente de siempre y copia las cuentas y los movimientos a su árbol.
- **Formato:**
  - `schemaVersion`, como los layouts de SDUI;
  - cada cuenta: `id`, `type`, `alias` y `maskedNumber`;
  - cada movimiento: `daysAgo`, `amountCents` (con signo), `description` y `category`.

  Las fechas son relativas (`daysAgo`), así el historial siempre se ve reciente.
- **Validación estricta** (`OpeningTemplate.fromJson`), con los mismos límites que las reglas: saldos nunca negativos,
  alias de hasta 60 caracteres y descripción de hasta 140. Una plantilla inválida o ausente no abre nada a medias: la
  falla se reporta a Crashlytics y el próximo inicio de sesión lo reintenta.
- **Reglas:** los usuarios autenticados solo pueden leer `templates/*`; escribir solo se puede con IAM (consola o
  `gcloud`), que no pasa por las reglas.
- **Sin respaldo en el código:** si la app trajera una copia por si falta el documento, la data seguiría quemada.

## Trade-offs

- **Un paso más de operación:** la plantilla debe estar publicada antes del primer cliente de un proyecto nuevo, como
  la plantilla de Remote Config.
- **Una lectura extra** en la apertura, solo la primera vez de cada cliente.
- **Los clientes existentes no cambian:** la plantilla solo afecta a las aperturas nuevas. Es lo correcto (el historial
  de un cliente no se reescribe), pero conviene saberlo antes de cambiarla.
- **Sigue siendo un historial de demostración:** sin un core bancario, la apertura simula los movimientos previos de
  un cliente. Se marcan como `source: seed`. Todo lo posterior, como las transferencias, son operaciones reales.

## Impacto a largo plazo

- **Con el plan Blaze,** la misma plantilla la leería una Cloud Function al crear el usuario; la app dejaría de
  escribir la apertura y el formato no cambiaría.
- **Ofertas por segmento:** con más documentos (`templates/opening_saver`…), la apertura podría elegir la plantilla
  según el segmento del cliente.
- **Un core bancario real** reemplazaría la plantilla por las cuentas reales del cliente, detrás del mismo
  `AccountsRepository`.
