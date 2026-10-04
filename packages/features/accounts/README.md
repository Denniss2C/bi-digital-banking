# accounts

Feature de cuentas de Nexo: cuentas, saldos, movimientos y transferencias. Dueño: `@team-accounts`.
Depende solo de `core`, `design_system` y `sdui`; el shell (`apps/banking_app`) lo compone.

## Datos (Cloud Firestore)

```text
users/{uid}                                       perfil (nombre, email, segmento…)
users/{uid}/accounts/{accountId}                  type, alias, maskedNumber, balanceCents, currency
users/{uid}/accounts/{accountId}/transactions     type, amountCents, description, category,
                                                  createdAt, balanceAfterCents, source,
                                                  transferId (solo transferencias)
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
  domain/   Account, AccountTransaction, TransactionPage/Cursor, AccountsSnapshot, AccountsRepository,
            TransferReceipt, TransferError y el caso de uso TransferBetweenOwnAccounts
  data/     FirestoreAccountsRepository, mapeo defensivo, errores de Firestore → Failure, datos de apertura
```

- **Paginación** por `createdAt` descendente. El cursor es opaco, para que el dominio no dependa de Firestore, y se
  pide un documento extra para saber si hay más.
- **Apertura de cuentas** (`ensureOpeningData`): la llama el shell al iniciar sesión. Corre dentro de una transacción
  idempotente: el primer inicio de sesión crea el perfil y dos cuentas con su historial, y los siguientes no cambian
  nada.
- **Documentos mal formados:** se traducen a `ServerFailure` en lugar de romper la app. En `watchAccounts`, los errores
  llegan como `Left` sin cortar el stream.

## Transferencias entre cuentas propias

- **Caso de uso `TransferBetweenOwnAccounts`:** valida lo que no depende de datos frescos (cuentas distintas, monto
  mayor a cero, máximo $5,000.00 y concepto de hasta 60 caracteres). El formulario usa las mismas reglas, así la UI y
  el dominio nunca discrepan.
- **`transfer` con `runTransaction`:** primero lee y después escribe. Rechaza el saldo insuficiente con el saldo de ese
  instante, actualiza los dos saldos y deja un débito y un crédito (`source: transfer`), todo o nada.
- **Idempotencia:** los dos movimientos usan el `transferId` como id de documento. Si el débito ya existe, `transfer`
  devuelve el comprobante original sin mover dinero, así que ni los reintentos de Firestore ni los del usuario cobran
  dos veces. Ver [`resilience.md`](../../../docs/resilience.md).
- **Errores:** una regla rota llega como `ValidationFailure` con el nombre de la regla (`TransferError`) y la pantalla
  muestra el mensaje exacto. Sin conexión llega un `NetworkFailure`: las transferencias necesitan internet.
- **Seguridad:** las reglas de Firestore validan la forma y la propiedad, pero no que el dinero se conserve. Ver los
  trade-offs de [ADR-003](../../../docs/adr/ADR-003-accounts-firestore.md); en producción, la transferencia la haría
  el servidor.

## Segmento del cliente

`watchSegment(userId)` emite el segmento de personalización de `users/{uid}.segment`: `new_user` al abrir la cuenta, o
`saver`, `traveler`, etc. El shell lo envía a Remote Config para elegir la home (ver
[ADR-005](../../../docs/adr/ADR-005-remote-config-personalization.md)). Los errores llegan como `Left` sin cortar el
stream.

## Componentes SDUI (home)

`accountsSduiComponents(repository:, userId:)` entrega los componentes de este feature para que el shell los registre
en la home. El contrato está en el [README de `sdui`](../../sdui/README.md).

- **`balance_card`:** saldo total en vivo en la tarjeta hero navy (reutiliza `BalanceHeroCard` y `AccountsCubit`).
  Con datos de la caché lo indica en el texto, y si falla ofrece reintentar.
- **`tx_list`:** últimos movimientos de **todas** las cuentas, del más nuevo al más viejo (`RecentMovementsCubit`).
  - Vuelve a pedirlos solo cuando cambia algún saldo (por ejemplo, después de una transferencia), sin polling.
  - Si una respuesta vieja llega después de una nueva, se descarta.
  - Los ids son únicos solo por cuenta (el débito y el crédito de una transferencia comparten id), así que la lista
    se ordena por fecha y nunca se indexa por id.

## Presentación

- **`AccountsPage`** (pestaña Cuentas): tarjeta hero navy con el saldo total y una tarjeta por cuenta.
- **`AccountDetailPage`** (`/accounts/:id`): saldo en vivo (sigue correcto después de una transferencia) y movimientos
  con **scroll infinito** de 20 en 20.
- **`TransferPage`** (`/accounts/transfer`): formulario según la pantalla Transferir del diseño (montos rápidos,
  saldo disponible en vivo, concepto y costo $0.00) y comprobante. Acepta montos como `150`, `150,50` o `1,500.00`.
  Los errores por campo aparecen después del primer intento.
- **Los 5 estados en las pantallas de Cuentas:**

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
