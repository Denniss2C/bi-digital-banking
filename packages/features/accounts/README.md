# accounts

Feature de cuentas de Nexo: cuentas, saldos, movimientos y transferencias. Dueño: `@team-accounts`.
Depende solo de `core`, `design_system` y `sdui`; el shell (`apps/banking_app`) lo compone.

## Datos (Cloud Firestore)

```text
users/{uid}                                       perfil (nombre, email, segmento…)
users/{uid}/accounts/{accountId}                  type, alias, maskedNumber, balanceCents, currency
users/{uid}/accounts/{accountId}/transactions     type, amountCents, description, category,
                                                  createdAt, balanceAfterCents, source
```

- **El dinero va en centavos enteros** (`balanceCents`, `amountCents`), nunca en `double`.
- **Movimientos:** son un libro inmutable. `source` distingue los datos de apertura (`seed`) de las operaciones
  reales (`transfer`).
- **Reglas de seguridad:** están en [`firebase/firestore.rules`](../../../firebase/firestore.rules). La decisión y sus
  trade-offs están en [ADR-003](../../../docs/adr/ADR-003-accounts-firestore.md).
- **Persistencia offline:** habilitada de forma explícita. `watchAccounts` informa `isFromCache` para que la UI avise
  cuando muestra datos guardados.

## Capas

```text
lib/src/
  domain/   Account, AccountTransaction, TransactionPage/Cursor, AccountsSnapshot, AccountsRepository
  data/     FirestoreAccountsRepository, mapeo defensivo, errores de Firestore → Failure, datos de apertura
```

- **Paginación** por `createdAt` descendente. El cursor es opaco, para que el dominio no dependa de Firestore, y se
  pide un documento extra para saber si hay más.
- **Apertura de cuentas** (`ensureOpeningData`): la llama el shell al iniciar sesión. Corre dentro de una transacción
  idempotente: el primer inicio de sesión crea el perfil y dos cuentas con su historial, y los siguientes no cambian
  nada.
- **Documentos mal formados:** se traducen a `ServerFailure` en lugar de romper la app. En `watchAccounts`, los errores
  llegan como `Left` sin cortar el stream.

## Presentación

- **`AccountsPage`** (pestaña Cuentas): tarjeta hero navy con el saldo total y una tarjeta por cuenta.
- **`AccountDetailPage`** (`/accounts/:id`): saldo en vivo (sigue correcto después de una transferencia) y movimientos
  con **scroll infinito** de 20 en 20.
- **Los 5 estados en ambas pantallas:**

  | Estado | Qué ve el usuario |
  |--------|-------------------|
  | carga | `AppLoading` |
  | éxito | datos |
  | vacío | "Estamos preparando tus cuentas" o "Aún no tienes movimientos" |
  | error | `AppErrorView` con reintento; si falla al cargar más, aviso inline sin perder lo ya cargado |
  | offline | datos de la caché con `AppOfflineBanner` |
- **Montos:** `formatUsd` / `formatSignedUsd` de `core`, con cifras tabulares. El verde y el rojo vienen de
  `AppSemanticColors` (AA).
- **Lector de pantalla:** cada tarjeta y cada movimiento se leen como una frase ("Supermaxi, gasto de $64.30, Hoy ·
  11:30").
- **Textos propios del feature:** `AccountsLocalizations` (es/en).

## Tests

```bash
cd packages/features/accounts && flutter test
```

Los de datos usan `fake_cloud_firestore`, un Firestore en memoria que soporta consultas, paginación y transacciones. Ojo: en el
fake **importa el orden de los modificadores** (`orderBy → startAfter → limit`); Firestore real es declarativo.
