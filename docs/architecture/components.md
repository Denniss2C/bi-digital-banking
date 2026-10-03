# Componentes

```mermaid
flowchart TB
    subgraph Device["📱 Dispositivo"]
        subgraph Shell["apps/banking_app (shell)"]
            Router["go_router"]
            DI["get_it + injectable"]
            Flavor["AppConfig (dev / prod)"]
            Debug["Panel de debug (solo dev)"]
        end

        subgraph Features["packages/features"]
            Auth["auth"]
            Accounts["accounts"]
            Notif["notifications"]
            Fx["fx_rates"]
        end

        subgraph Platform["Paquetes de plataforma"]
            Core["core<br/>dio · Retry · Chaos · Failures · logger · connectivity"]
            DS["design_system<br/>tokens · temas · componentes"]
            SDUI["sdui<br/>JSON → registro → widgets"]
        end

        Cache[("hive_ce<br/>caché local")]
    end

    subgraph Firebase["☁️ Firebase"]
        FAuth["Auth"]
        FS[("Cloud Firestore")]
        FCM["Cloud Messaging"]
        RC["Remote Config"]
        Crash["Crashlytics"]
        Perf["Performance"]
    end

    FxApi["🌐 API pública de tipo de cambio"]

    Shell --> Features
    Features --> Platform
    Debug -. configura .-> Core
    Auth --> FAuth
    Accounts --> FS
    Notif --> FCM
    SDUI --> RC
    Fx --> Core --> FxApi
    Core --> Cache
    Shell --> Crash
    Shell --> Perf

    classDef planned stroke-dasharray: 5 5;
    class Router,DI,Flavor,Debug,Auth,Accounts,Notif,Fx,Core,DS,SDUI,Cache,FAuth,FS,FCM,RC,Crash,Perf,FxApi planned;
```

| Componente | Responsabilidad | Equipo dueño |
|------------|-----------------|--------------|
| Shell | Composición, routing, DI global, flavors | `@team-platform` |
| core | Red resiliente, errores tipados, logger, conectividad, caché | `@team-platform` |
| design_system | Tokens, temas claro/oscuro, componentes accesibles | `@team-design-system` |
| sdui | Motor Server-Driven UI | `@team-sdui` |
| auth | Onboarding, registro, login | `@team-auth` |
| accounts | Cuentas, saldos, movimientos, transferencias | `@team-accounts` |
| notifications | Notificaciones push (FCM) | `@team-notifications` |
| fx_rates | Micro app de tipo de cambio | `@team-fx` |
