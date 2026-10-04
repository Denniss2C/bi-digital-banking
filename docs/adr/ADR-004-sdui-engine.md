# ADR-004: Server-Driven UI con un catálogo de componentes de negocio

- **Estado:** Aceptado
- **Fecha:** 2026-10-04
- **Autores:** @Denniss2C
- **Equipos afectados:** @team-sdui, @team-platform, @team-accounts, @team-fx

## Problema

La plataforma debe **incorporar experiencias, contenidos o componentes sin publicar una versión nueva** y **adaptar
la experiencia** según el perfil del usuario. Además, varios equipos aportan a la misma pantalla de inicio: cuentas,
divisas y marketing.

El servidor tiene que poder decidir qué se muestra y en qué orden, sin que eso rompa la accesibilidad, la
consistencia visual ni la estabilidad cuando el JSON llega mal o desde una versión más nueva.

## Alternativas

| Alternativa | A favor | En contra |
|-------------|---------|-----------|
| A. **JSON propio con componentes de negocio** (`balance_card`, `promo_banner`…) y un registry | Cada componente se diseña, se testea y cumple AA dentro de la app; el servidor solo compone y parametriza. El contrato es pequeño y fácil de validar. | Un **tipo** de componente nuevo requiere publicar la app (las combinaciones, el orden y el contenido no). |
| B. `rfw` (Remote Flutter Widgets, del equipo de Flutter) | Árboles de widgets arbitrarios desde el servidor. | El contrato es a nivel de widget: desde el servidor se puede romper la accesibilidad o el diseño. Tiene su propio formato y herramientas, y una superficie de error mayor. |
| C. JSON a nivel de widget (`json_dynamic_widget` y similares) | Máxima flexibilidad. | Los mismos riesgos que B, y el JSON crece y se vuelve difícil de revisar. |
| D. WebView con contenido web | Cambia sin publicar y sin límites. | Peor experiencia y accesibilidad, sin offline y con otra pila que mantener. |

## Decisión

**Alternativa A.** El contrato está documentado en el [README de `sdui`](../../packages/sdui/README.md):
`{"schemaVersion": 1, "components": [{"type", "id", "props"}]}`.

- **Parser tolerante.** Un componente mal formado se omite y se reporta. Solo se rechaza el documento entero si no es
  JSON, no tiene la forma esperada o declara un `schemaVersion` mayor al que la app entiende.
- **Registry por tipo.** Cada feature registra sus componentes y el shell los compone, así los features siguen sin
  depender entre sí. Un tipo desconocido se ignora (forward compatibility). Un tipo registrado dos veces falla al
  arrancar.
- **Frontera de error por componente.** Si un componente tiene props inválidas, se omite solo ese componente.
- **Fallback embebido.** La app trae un layout por defecto en el mismo formato. Se usa cuando el remoto falta, es
  inválido o no tiene nada que esta app pueda mostrar.
- **Acciones declarativas.** Por ahora solo `navigate`, y solo a rutas internas; las ejecuta el shell. Una acción
  desconocida oculta el botón.
- **Estilo semántico.** El servidor elige un tono (`primary`, `secondary`, `neutral`), nunca un color crudo, así el
  contraste AA lo garantiza el design system.

## Trade-offs

- **Componentes nuevos requieren publicar la app.** Se mitiga con un catálogo que cubre la home del diseño y con
  `promo_banner`, que es contenido libre. Las versiones anteriores ignoran los tipos que no conocen.
- **El JSON se valida en el cliente.** Puede llegar mal; lo cubren el parser tolerante, la frontera de error y el
  fallback. Lo ideal es validar el JSON contra el contrato antes de publicarlo (pendiente: un JSON Schema en CI).
- **Cambios de contrato.** Un cambio incompatible sube `schemaVersion`; Remote Config puede segmentar por versión de
  app para que las versiones viejas reciban un layout que entienden.

## Impacto a largo plazo

- **Equipos nuevos** suman componentes registrándolos, sin tocar el motor.
- **El motor no depende de la fuente.** Hoy es Remote Config (`feat/personalization`); mañana puede ser Firestore
  (`layouts/{screenId}`) u otro backend, para cualquier pantalla.
- **Señal para revisar la decisión:** si cada semana hacen falta tipos nuevos, evaluar `rfw` para piezas puntuales
  dentro de un componente de este catálogo.
