# Flujos clave

Diagramas de secuencia de lo implementado, con los nombres reales de las clases.

1. [Arranque](#1-arranque)
2. [Inicio de sesión y apertura de cuentas](#2-inicio-de-sesión-y-apertura-de-cuentas)
3. [Home personalizada (SDUI + Remote Config)](#3-home-personalizada-sdui--remote-config)
4. [Transferencia idempotente](#4-transferencia-idempotente)
5. [Divisas con caché stale-while-revalidate](#5-divisas-con-caché-stale-while-revalidate)
6. [Tocar una notificación](#6-tocar-una-notificación)

## 1. Arranque

```mermaid
sequenceDiagram
    participant Main as main_dev / main_prod
    participant Boot as bootstrap
    participant FB as Firebase
    participant DI as get_it (entorno = flavor)
    participant App as App + go_router

    Main->>Boot: AppConfig del flavor + FirebaseOptions
    Boot->>FB: Firebase.initializeApp
    Boot->>Boot: HiveKeyValueStore.open (caché local)
    Boot->>DI: configureDependencies (@dev registra el panel y el caos)
    Boot->>Boot: errores no capturados → Telemetry (Crashlytics)
    Boot->>DI: SessionEffects · AppObservability.start · PushCoordinator.start
    Boot->>App: runApp
    App->>App: /splash (repite el splash nativo)
    Note over App: authRedirect decide según la sesión:<br/>onboarding, login o /home
```

## 2. Inicio de sesión y apertura de cuentas

```mermaid
sequenceDiagram
    actor U as Cliente
    participant Cubit as SignInCubit
    participant Auth as FirebaseAuthRepository
    participant Session as SessionCubit
    participant Eff as SessionEffects
    participant Acc as FirestoreAccountsRepository
    participant FS as Firestore
    participant Push as PushCoordinator
    participant Obs as AppObservability

    U->>Cubit: correo + contraseña
    Cubit->>Auth: signIn
    Auth-->>Session: userChanges → SessionAuthenticated
    Session-->>Eff: nueva sesión
    Eff->>Acc: ensureOpeningData (en cada login, idempotente)
    Acc->>FS: runTransaction: lee users/{uid}
    alt cliente nuevo
        Acc->>FS: lee templates/opening (ADR-007)
        Acc->>FS: escribe perfil, 2 cuentas y sus movimientos (source: seed)
    else ya abierto
        Acc-->>Eff: no escribe nada
    end
    Session-->>Push: pide permiso y guarda el token en users/{uid}.fcmTokens
    Session-->>Obs: setUser(uid) + evento login
    Note over Session: el router pasa de /login a /home
```

Si la apertura falla por red, se reintenta en el próximo login. Si la plantilla falta o es inválida, no se escribe nada
y se reporta a Crashlytics.

## 3. Home personalizada (SDUI + Remote Config)

```mermaid
sequenceDiagram
    participant Perso as PersonalizationCubit
    participant FS as Firestore
    participant RC as Remote Config
    participant Home as HomePage
    participant Res as resolveSduiLayout
    participant View as SduiView

    Perso->>FS: escucha users/{uid}.segment
    FS-->>Perso: segment = traveler
    Perso->>RC: setCustomSignals(segment) + fetchAndActivate
    RC-->>Perso: home_layout del segmento + flags
    Perso-->>Home: PersonalizationConfig
    Home->>Res: JSON remoto, layout embebido, registro
    Res-->>Home: remoto si es válido; si no, el embebido (con motivos)
    Home->>View: layout + createHomeRegistry
    View->>View: cada tipo → widget del registro (balance_card, tx_list, fx_widget…)
    Note over View: tipo desconocido: se omite<br/>componente que falla: se aísla y se reporta
    RC-->>Perso: onConfigUpdated (publicación en la consola)
    Perso-->>Home: layout nuevo, sin reiniciar
```

Las acciones de los componentes (`navigate`) solo abren pantallas de la app (`AppRoutes.isAppLocation`) y solo si su
flag está activo (`AppRoutes.isEnabled`).

## 4. Transferencia idempotente

```mermaid
sequenceDiagram
    actor U as Cliente
    participant Cubit as TransferCubit
    participant UC as TransferBetweenOwnAccounts
    participant Repo as FirestoreAccountsRepository
    participant FS as Firestore

    Cubit->>Repo: newTransferId (una vez por formulario)
    U->>Cubit: origen, destino, monto, concepto
    Cubit->>UC: validate (las mismas reglas que la UI)
    UC->>Repo: transfer(transferId, …)
    Repo->>FS: runTransaction: lee las 2 cuentas y transactions/{transferId}
    alt el movimiento ya existe (reintento)
        Repo-->>Cubit: el recibo original, sin mover dinero
    else saldo insuficiente
        Repo-->>Cubit: ValidationFailure(insufficientFunds)
    else ok
        Repo->>FS: actualiza los 2 saldos + crea débito y crédito (id = transferId)
    end
    Repo-->>Cubit: recibo o Failure tipado
    Note over Cubit: un reintento usa el mismo transferId:<br/>nunca cobra dos veces
```

Sin conexión, la transacción falla con `NetworkFailure` y no escribe nada: las transacciones de Firestore no funcionan
offline.

## 5. Divisas con caché stale-while-revalidate

```mermaid
sequenceDiagram
    participant Cubit as FxCubit
    participant Repo as ExchangeRateApiRepository
    participant Cache as KeyValueStore (hive_ce)
    participant Dio as dio (Retry · Chaos en dev · Performance)
    participant API as open.er-api.com

    Cubit->>Repo: watchRates(forceRefresh)
    Repo->>Cache: lee las últimas tasas
    Cache-->>Cubit: tasas guardadas, al instante
    alt el proveedor ya publicó tasas nuevas, o pull to refresh
        Repo->>Dio: GET /v6/latest/USD
        Dio->>API: hasta 3 intentos con backoff y jitter
        alt responde
            API-->>Repo: tasas nuevas
            Repo->>Cache: guarda
            Repo-->>Cubit: tasas nuevas ("Tasas al día")
        else falla
            Repo-->>Cubit: tasas guardadas + refreshFailure (aviso offline)
        end
    end
```

## 6. Tocar una notificación

```mermaid
sequenceDiagram
    participant FCM as Firebase Cloud Messaging
    participant Svc as FirebasePushService
    participant Coord as PushCoordinator
    participant Router as go_router

    FCM-->>Svc: mensaje con data.route = /fx
    Svc-->>Coord: openedMessages / initialMessage (app cerrada)
    Coord->>Coord: AppRoutes.isAppLocation(route)
    alt ruta externa o desconocida
        Coord-->>Coord: solo abre la app
    else sin sesión todavía
        Coord-->>Coord: la guarda hasta el login
    else
        Coord->>Router: go(/fx) + evento push_opened
    end
```

Con la app abierta, Android no muestra la notificación: `ForegroundPushListener` muestra un aviso con **Ver**, que pasa
por el mismo `open`.
