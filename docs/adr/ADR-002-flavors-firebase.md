# ADR-002: Entornos dev/prod con flavors sobre un único proyecto Firebase

- **Estado:** Aceptado
- **Fecha:** 2026-10-03
- **Autores:** @Denniss2C
- **Equipos afectados:** @team-platform y todos los equipos de features

## Problema

Necesitamos separar la app con la que se desarrolla y se hace la demo (con panel de debug y modo caos)
de la que iría a producción. Hay tres requisitos:

- que una ejecución por error nunca apunte a producción;
- que cada entorno tenga identidad propia en el dispositivo, para poder instalar ambos a la vez;
- que cada entorno tenga identidad propia en Firebase, para separar crashes, métricas y tokens de push.

Restricciones: entrega en tres días, un solo desarrollador y plan gratuito (Spark) de Firebase.

## Alternativas

| Alternativa | A favor | En contra |
|-------------|---------|-----------|
| A. Flavors + **un proyecto** Firebase con **una app por flavor** | Una sola consola y una sola configuración de Auth, Firestore y Remote Config. Crashlytics, Analytics y FCM quedan separados por app. Se configura rápido. | Dev y prod **comparten datos** (Auth, Firestore, Remote Config). |
| B. Flavors + **un proyecto Firebase por entorno** | Aislamiento total de datos, reglas y cuotas. Es lo estándar en banca. | Hay que duplicar Auth, reglas, índices y Remote Config, y mantenerlos sincronizados. Cuesta más tiempo del disponible. |
| C. Sin flavors, solo `--dart-define` | Simple; no toca Gradle ni Xcode. | Mismo applicationId y bundle ID: no se pueden instalar ambas, y push y crashes se mezclan. Es fácil equivocarse de entorno. |

## Decisión

Flavors nativos `dev` y `prod` (product flavors en Android; configuraciones de build y schemes en iOS),
con un entry point por flavor y un `AppConfig` inmutable, sobre **un único proyecto Firebase con una app
registrada por flavor** (alternativa A). El panel de debug y el modo caos solo existen en dev
(`AppConfig.enableDebugTools`). `flutter run` sin argumentos usa dev.

## Trade-offs

- **Datos compartidos entre dev y prod.** Mitigaciones:
  - reglas de Firestore que limitan a cada usuario a su propio árbol;
  - usuarios de prueba propios de dev;
  - condiciones por app (`app.id`) en Remote Config para que un cambio de layout o un flag no afecte a ambos entornos.
- **Las herramientas de debug se excluyen por flag, no por compilación.** Su código existe en el binario
  de prod, aunque no se puede acceder a él.
- **Nombres e IDs repetidos en Dart, Gradle y Xcode.** Un test (`app_config_test.dart`) verifica que los
  nombres coincidan; los IDs están centralizados en `build.gradle.kts` y en `ios/Flutter/<flavor>.xcconfig`.
- **iOS necesita un build phase propio para el `GoogleService-Info.plist`.** El script de flutterfire
  omite en silencio las configuraciones Release y Profile (ver `docs/deployment-operations.md`).

## Impacto a largo plazo

- Migrar a un proyecto por entorno (alternativa B) es incremental: los flavors ya existen, solo cambia el
  `--project` del comando de flutterfire de dev y hay que replicar la configuración del backend. Señales
  para hacerlo: datos reales de clientes, personas externas con acceso a dev, o necesidad de probar
  reglas y migraciones sin riesgo para producción.
- Un tercer entorno (por ejemplo `staging`) implica: un product flavor, tres configuraciones y un scheme
  en iOS siguiendo los pasos de `tool/setup_ios_flavors.rb`, un entry point y un comando de flutterfire.
