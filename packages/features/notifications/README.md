# notifications

Notificaciones push de Nexo con Firebase Cloud Messaging. Dueño: `@team-notifications`. Depende de `core`; **no
tiene UI**: el shell decide cómo mostrar y abrir los mensajes (`PushCoordinator`).

## Piezas

- **`PushService`** (`FirebasePushService`) envuelve FCM:
  - permiso: Android 13+ e iOS muestran un diálogo del sistema una sola vez;
  - token del dispositivo y sus renovaciones;
  - mensajes recibidos con la app abierta;
  - toques en notificaciones con la app en segundo plano;
  - el mensaje que abrió la app estando cerrada.
- **`PushMessage`:** `title`, `body` y `route`, que sale de `data.route` del mensaje, por ejemplo `/fx`.
- **`PushTokenRegistry`** (`FirestorePushTokenRegistry`) guarda los tokens en `users/{uid}.fcmTokens` con
  `arrayUnion`, porque un usuario puede tener varios dispositivos. Las reglas de Firestore solo permiten escribir el
  propio documento.

## Cómo lo usa la app

El `PushCoordinator` del shell:

| Momento | Qué hace |
|---------|----------|
| Inicio de sesión | Pide el permiso y guarda el token (y cada token renovado) |
| Cierre de sesión | Quita el token, para que un dispositivo compartido no reciba los avisos del usuario anterior |
| Toque en una notificación | Abre `route` si es una pantalla de la app (la misma regla que las acciones SDUI); sin sesión, espera al login |
| Mensaje con la app abierta | Android no muestra nada, así que la app muestra un aviso con "Ver" |

Cómo enviar una notificación de prueba: [`deployment-operations.md`](../../../docs/deployment-operations.md) §7.

## Tests

```bash
cd packages/features/notifications && flutter test
```

FCM mockeado (permisos, token, mensajes) y el registro de tokens con `fake_cloud_firestore` (sin duplicados, borrado
y el resto del perfil intacto).
