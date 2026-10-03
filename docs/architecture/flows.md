# Flujos clave

> Estado: **planificado**. Los diagramas se actualizan a medida que se implementan los pasos.

## 1. Arranque de la app

```mermaid
sequenceDiagram
    autonumber
    participant M as main_dev / main_prod
    participant FB as Firebase
    participant DI as get_it
    participant S as Splash
    participant RC as Remote Config
    participant A as Firebase Auth

    M->>M: AppConfig del flavor
    M->>FB: initializeApp(options del flavor)
    M->>FB: activar Crashlytics y Performance
    M->>DI: configureDependencies(config)
    M->>S: runApp → /splash
    S->>RC: fetchAndActivate (con timeout)
    S->>A: ¿sesión activa?
    alt sesión activa
        S->>S: navegar a /home
    else sin sesión
        S->>S: navegar a /login
    end
```

## 2. Petición HTTP resiliente

El `RetryInterceptor` se registra antes que el `ChaosInterceptor`: cada reintento vuelve a
pasar por el modo caos, así los fallos inyectados ejercitan la lógica real de reintentos.

```mermaid
sequenceDiagram
    autonumber
    participant B as Bloc
    participant Repo as Repository
    participant Retry as RetryInterceptor
    participant Chaos as ChaosInterceptor
    participant API as API externa
    participant C as Caché (hive_ce)

    B->>Repo: getRates()
    Repo->>Retry: GET (dio)
    loop máx. 3 intentos, solo errores transitorios
        Retry->>Chaos: request
        Note over Chaos: solo dev: latencia, % de fallos, sin red
        Chaos->>API: request
        API-->>Retry: respuesta o error
        Retry->>Retry: si es transitorio, espera backoff exponencial + jitter
    end
    alt éxito
        Retry-->>Repo: 200 OK
        Repo->>C: guardar con fecha de actualización
        Repo-->>B: Right(rates)
    else fallo definitivo
        Repo->>C: leer última copia
        alt hay caché
            Repo-->>B: datos en caché + aviso offline
        else sin caché
            Repo-->>B: Left(NetworkFailure o ServerFailure)
        end
    end
```

## 3. Render Server-Driven UI

```mermaid
flowchart LR
    Source["Remote Config / Firestore<br/>JSON de pantalla"] --> Parse["Parser + validación"]
    Parse --> Reg["Registro de widgets<br/>type → builder"]
    Reg --> Tree["Árbol de widgets"]
    Reg -. tipo desconocido .-> Fallback["Fallback seguro"]
```
