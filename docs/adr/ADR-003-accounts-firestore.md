# ADR-003: Datos bancarios en Firestore con escrituras desde el cliente

- **Estado:** Aceptado
- **Fecha:** 2026-10-03
- **Autores:** @Denniss2C
- **Equipos afectados:** @team-accounts, @team-platform

## Problema

La prueba exige **interacción real con servicios**: cuentas, saldos, movimientos y transferencias deben vivir en un
backend real, no en datos fijos de la app. No hay un core bancario disponible, el proyecto Firebase está en el plan
gratuito **Spark** (sin Cloud Functions) y el plazo es de tres días.

## Alternativas

| Alternativa | A favor | En contra |
|-------------|---------|-----------|
| A. **Firestore con escrituras desde el cliente**, protegidas por reglas de seguridad | Backend real con tiempo real y persistencia offline incluidos. Funciona en Spark y se integra rápido. | El cliente escribe saldos: las reglas validan forma y propiedad, pero no todas las invariantes de negocio. |
| B. Firestore + **Cloud Functions** (callable) para abrir cuentas y transferir | Lógica sensible del lado del servidor, como en banca real. | Requiere el plan Blaze (facturación) y más tiempo de desarrollo y despliegue. |
| C. API simulada propia (mock server) | Control total de las respuestas. | Son datos simulados, que la prueba descarta; además habría que operarla. |

## Decisión

**Alternativa A.**
- Estructura: `users/{uid}`, `users/{uid}/accounts/{id}` y `.../transactions/{id}`, con el dinero en **centavos
  enteros**.
- **Apertura de cuentas:** la crea la app en el primer inicio de sesión, dentro de una transacción idempotente y
  marcada con `source: seed`.
- **Transferencias:** serán operaciones reales con `runTransaction`, en `feat/transfers`.
- **Reglas** (`firebase/firestore.rules`):
  - cada usuario solo accede a su árbol;
  - se valida la forma de cuentas y movimientos, y que los saldos no sean negativos;
  - una cuenta solo puede cambiar su saldo;
  - **los movimientos son inmutables** (libro contable);
  - se deniega todo lo demás.

## Trade-offs

- **Confianza en el cliente.** Un cliente modificado podría alterar los saldos de **sus propias** cuentas dentro de lo
  que permiten las reglas. Nunca puede tocar datos de otro usuario ni borrar o editar movimientos. Es aceptable para
  la demo y está documentado; en producción, la alternativa B.
- **Datos de apertura generados por la app** (historial inicial de movimientos). Se marcan como `seed` para
  distinguirlos de las operaciones reales.
- **Sin tests automáticos de las reglas.** Se validan al compilar y desplegar (`firebase deploy`). _Planificado:_
  tests con el emulador de Firestore.

## Impacto a largo plazo

- **Migrar a la alternativa B no toca la UI.** Las pantallas dependen de `AccountsRepository`; mover
  `ensureOpeningData` y las transferencias a funciones callable solo cambia la implementación de datos.
- Las reglas ya fijan el contrato de datos, que se mantiene si las escrituras pasan al servidor.
- **Señales para migrar:** clientes reales, montos reales, o requisitos de auditoría y antifraude.
