# design_system

Design system "Nexo Digital": tokens, temas claro y oscuro y componentes accesibles.
Fuente de verdad visual: [`docs/design/DESIGN.md`](../../docs/design/DESIGN.md). Dueño: `@team-design-system`.

## Uso

```dart
import 'package:design_system/design_system.dart';

MaterialApp(theme: AppTheme.light(), darkTheme: AppTheme.dark());

AppButton(label: l10n.transfer, onPressed: onTransfer);
AppCard(variant: AppCardVariant.hero, child: balance);
AppLoading(semanticsLabel: l10n.loadingAccounts);
AppOfflineBanner(message: l10n.offlineNotice); // sobre datos de la caché
AppErrorView(title: l10n.errorTitle, retryLabel: l10n.retry, onRetry: cubit.load);
AppEmptyView(title: l10n.noMovements);
NexoLogo(size: 32); // markOnly: true sobre fondos navy, como el splash

final colors = context.semanticColors; // positive, negative, warning, card, heroSurface…
Text(amount, style: textTheme.titleLarge!.tabular); // cifras tabulares para montos
```

Los componentes reciben sus textos por parámetro: la traducción la hace la app.

## Qué incluye

| Pieza | Contenido |
|-------|-----------|
| Tokens | `AppColors`, `AppSpacing` (grilla de 8 pt, toque mínimo de 48 px), `AppRadius` (12 botones, 16 tarjetas, pill) y `AppShadows` |
| Tipografía | Inter **empaquetada** (400, 600 y 700; licencia OFL en `fonts/OFL.txt`), escala del diseño mapeada a Material 3 y `.tabular` para montos |
| Temas | `AppTheme.light()` / `.dark()` con `ColorScheme` explícito y la extensión `AppSemanticColors` |
| Componentes | `AppButton` (primario, secundario, terciario y estado de carga), `AppCard` (normal y hero), `AppLoading`, `AppErrorView` y `AppEmptyView` |
| Marca | `NexoLogo` y `NexoLogoPainter`: el logo vectorial (ver abajo) |

## Accesibilidad

- **Contraste AA verificado por tests** (`test/theme/contrast_test.dart`) en los dos temas. Se corrigieron tres colores del
  diseño original:

  | Uso | Diseño | Tema |
  |-----|--------|------|
  | Texto sobre naranja | blanco (2.45:1) | navy `#1B2A41` (5.88:1) |
  | Montos positivos | `#10B981` (2.54:1) | `#006C49` (6.48:1) |
  | Montos negativos y errores | `#EF4444` (3.76:1) | `#BA1A1A` (6.46:1) |

- **Tema oscuro:** derivado de los mismos tokens, porque el diseño solo define el claro. También cumple AA.
- **Áreas táctiles** de al menos 48 px.
- **Semántica:** el botón en carga conserva su etiqueta, `AppLoading` exige una etiqueta para lectores de pantalla y los
  errores se anuncian (`liveRegion`).
- **Texto escalable:** hay tests con texto al 200% en pantallas de 320 px que verifican que nada se desborde.

## Logo

`NexoLogo` dibuja el logo del diseño ([`logo_nexo_banco_digital.png`](../../docs/design/screens/logo_nexo_banco_digital.png))
como vector, con la geometría medida sobre esa imagen: la "N" naranja, el trazo blanco sobre ella y el punto naranja,
en el cuadrado navy.

- **Por qué vectorial:** en la imagen del diseño el ícono mide 272 px; ampliado a los 1024 px que pide iOS se vería
  borroso.
- **Una sola fuente:** el ícono de la app y las imágenes del splash se generan desde el mismo `NexoLogoPainter`
  (`make brand-assets`, ver [`deployment-operations.md`](../../docs/deployment-operations.md) §4).
- **Variantes:** el logo completo (cuadrado navy) para fondos claros y `markOnly` (solo la marca) para fondos navy, como
  el splash. Sus trazos blancos necesitan un fondo oscuro.
- **Accesibilidad:** se anuncia como imagen "Nexo". Con `semanticsLabel: null` es decorativo, para cuando el nombre ya
  está escrito al lado.
- **Desvío del diseño:** la marca va centrada en el cuadrado. En la imagen de Stitch está corrida a la derecha (cerca del
  5 %), y eso se nota en las máscaras redondas de los íconos de Android.

## Trampa conocida: textos en `AppCard.hero`

Los estilos del tema (`textTheme.*`) traen el color `onSurface` (oscuro), que **pisa** el color claro que la tarjeta hero
aplica por defecto. Dentro de una tarjeta hero, cada texto con estilo explícito debe usar
`context.semanticColors.onHeroSurface`.

## Agregar un componente

1. Usar solo tokens y colores del tema (nada de colores sueltos).
2. Recibir los textos por parámetro y exponer la semántica (etiqueta, botón, encabezado).
3. Agregar tests de comportamiento, semántica y texto al 200%.
