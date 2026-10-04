/// Home layout embedded in the app (SDUI contract, see `packages/sdui`).
///
/// It replicates the "Inicio" screen of the design and is used whenever the
/// remote layout is missing or unusable, so the home never breaks. `fx_widget`
/// is skipped until the fx_rates feature registers it.
const defaultHomeLayout = r'''
{
  "schemaVersion": 1,
  "components": [
    {
      "type": "balance_card",
      "id": "balance",
      "props": {
        "action": { "type": "navigate", "route": "/accounts" }
      }
    },
    {
      "type": "quick_actions",
      "id": "shortcuts",
      "props": {
        "title": { "es": "Operaciones frecuentes", "en": "Frequent actions" },
        "items": [
          {
            "label": { "es": "Transferir", "en": "Transfer" },
            "icon": "send",
            "highlighted": true,
            "action": { "type": "navigate", "route": "/accounts/transfer" }
          },
          {
            "label": { "es": "Mis cuentas", "en": "My accounts" },
            "icon": "accounts",
            "action": { "type": "navigate", "route": "/accounts" }
          },
          {
            "label": { "es": "Divisas", "en": "Exchange" },
            "icon": "fx",
            "action": { "type": "navigate", "route": "/fx" }
          },
          {
            "label": { "es": "Perfil", "en": "Profile" },
            "icon": "profile",
            "action": { "type": "navigate", "route": "/profile" }
          }
        ]
      }
    },
    {
      "type": "promo_banner",
      "id": "promo-flexible-savings",
      "props": {
        "eyebrow": { "es": "Nexo Ahorro Flexible", "en": "Nexo Flexible Savings" },
        "title": {
          "es": "Tu dinero, disponible cuando lo necesitas",
          "en": "Your money, available whenever you need it"
        },
        "body": {
          "es": "Ahorra sin plazos forzosos y mueve dinero entre tus cuentas al instante.",
          "en": "Save with no lock-in periods and move money between your accounts instantly."
        },
        "icon": "savings",
        "tone": "primary",
        "cta": {
          "label": { "es": "Transferir ahora", "en": "Transfer now" },
          "action": { "type": "navigate", "route": "/accounts/transfer" }
        }
      }
    },
    {
      "type": "fx_widget",
      "id": "fx",
      "props": { "currencies": ["EUR", "COP", "PEN"] }
    },
    {
      "type": "tx_list",
      "id": "recent-movements",
      "props": {
        "title": { "es": "Movimientos recientes", "en": "Recent activity" },
        "limit": 5,
        "action": { "type": "navigate", "route": "/accounts" }
      }
    }
  ]
}
''';
