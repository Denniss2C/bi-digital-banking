---
name: Nexo Digital
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#554336'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#887364'
  outline-variant: '#dbc2b0'
  surface-tint: '#914d00'
  primary: '#914d00'
  on-primary: '#ffffff'
  primary-container: '#f28c28'
  on-primary-container: '#5d2f00'
  inverse-primary: '#ffb77d'
  secondary: '#505f79'
  on-secondary: '#ffffff'
  secondary-container: '#d1e0ff'
  on-secondary-container: '#54637d'
  tertiary: '#006c49'
  on-tertiary: '#ffffff'
  tertiary-container: '#19bc84'
  on-tertiary-container: '#00452d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdcc3'
  primary-fixed-dim: '#ffb77d'
  on-primary-fixed: '#2f1500'
  on-primary-fixed-variant: '#6e3900'
  secondary-fixed: '#d5e3ff'
  secondary-fixed-dim: '#b8c7e5'
  on-secondary-fixed: '#0c1c32'
  on-secondary-fixed-variant: '#394760'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a high-trust, progressive digital banking experience tailored for Ecuador's dollarized economy. The aesthetic pairs the energetic optimism of a warm citrus primary tone with the institutional solidity of deep navy, delivering an atmosphere that feels both regulatory-grade secure and consumer-tech effortless.

Key stylistic pillars:
- **Calibrated Warmth & Solidity:** Vibrant orange serves as a focal activation color for conversion paths, balances, and highlights, grounded continuously by rich navy structural elements.
- **Card-Centric Modular Architecture:** Surfaces operate as tactile, floating financial modules, providing rapid visual hierarchy without dense tabular interfaces.
- **Accessible & Transparent:** Interfaces prioritize radical legibility, high contrast, transparent status communications, and ergonomic mobile-first interactions that meet or exceed WCAG AA standards.

## Colors

The palette is tuned specifically for light-mode clarity, high sunlight readability, and institutional confidence.

### Palette Architecture
- **Primary (`#F28C28`):** Directs the primary action vector—card activations, decisive CTAs, and interactive focus states. Contrast against white is balanced using dark text for embedded elements or paired with high-contrast neutral backgrounds.
- **Secondary (`#1B2A41`):** Serves as the structural anchor. Used across navigation chrome, high-level headers, and high-impact account summary card surfaces to create institutional authority.
- **Tertiary & Semantics:**
  - Success / Income: `#10B981` (emerald for incoming USD wires, positive yields).
  - Warning: `#F59E0B` (amber for pending settlements, limits reached).
  - Destructive / Expense: `#EF4444` (crimson for outgoing transfers, card freeze states).
- **Neutrals & Surfaces:**
  - Base canvas: `#F8FAFC`
  - Subdued / Card background: `#FFFFFF`
  - Border and Dividers: `#E2E8F0`
  - Subtle interactive state: `#F1F5F9`
  - Secondary text / Muted details: `#64748B`
  - Primary text / Metric numbers: `#0F172A`

## Typography

The type scale relies entirely on Inter to ensure clean tabular numerals, dense vertical alignments, and predictable metric layouts across mobile screens.

- **Tabular Figures (`tnum`):** All monetary figures, percentage yields, account digits, and transaction movements must render with tabular figures enabled (`font-feature-settings: 'tnum' 1`).
- **Currency Styling:** The `$` symbol is scaled down to 75% baseline-aligned within primary balances to emphasize the integral amount.
- **Hierarchy:** Headline styles establish strict section authority; `label-md` and `label-sm` govern status flags, chip elements, and secondary category badges.

## Layout & Spacing

A strictly mobile-first architecture utilizing an 8pt base grid system.

- **Canvas Margins:** Fixed `1rem` (16px) side paddings preserve interaction real estate on compact viewports while preventing horizontal spill.
- **Vertical Flow:** Stack spacing between discrete card modules defaults to `1rem` (16px). Nested component padding inside cards scales between `1rem` (compact) and `1.25rem` (prominent balances).
- **Touch Bounds:** Touch target envelopes adhere strictly to `>= 48px` vertically, regardless of the internal visual boundary of text links or icon buttons.

## Elevation & Depth

Visual separation relies on clean surface layering paired with ultra-diffused, ambient drop shadows rather than heavy structural borders.

- **Level 0 (Base Canvas):** Background `#F8FAFC`. Completely non-elevated.
- **Level 1 (Cards & Modules):** Pure white `#FFFFFF` surface enclosed by a subtle 1px border of `#E2E8F0` and an ambient shadow: `box-shadow: 0 1px 3px 0 rgba(15, 23, 42, 0.04), 0 1px 2px -1px rgba(15, 23, 42, 0.02)`.
- **Level 2 (Active Sheets / Elevated Modals):** White `#FFFFFF` with heightened ambient soft shadow: `box-shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.08), 0 8px 10px -6px rgba(15, 23, 42, 0.03)`.
- **Primary Hero Cards (Navy Anchor):** `#1B2A41` filled cards deploy an organic color-tinted elevation: `box-shadow: 0 12px 24px -8px rgba(27, 42, 65, 0.3)`.

## Shapes

The geometric identity balances clean precision with organic touch ergonomics.

- **Container Modules & Cards:** Standardized strictly at `1rem` (16px) corner radius to create smooth content groupings.
- **Interactive Buttons:** Standardized at `0.75rem` (12px) corner radius, providing visual rhythm against 16px parent card bounds.
- **Quick-Action & Utility Buttons:** Full pill or circle geometry (`9999px` radius) for horizontal tags, category filters, and quick transaction circular anchors.

## Components

### Buttons
- **Primary:** Warm orange `#F28C28` background, white `#FFFFFF` text, 12px corner radius, minimum height 48px. Pressed state dims to `#D97706`.
- **Secondary:** Deep Navy `#1B2A41` background, white text. Used exclusively when juxtaposed against standard light surfaces.
- **Tertiary / Subdued:** Surface `#F1F5F9` background, `#0F172A` text, 0 border, 12px corner radius.
- **Quick Action Circular:** 56px circle, white `#FFFFFF` background with 1px border in `#E2E8F0`, ambient shadow. Centered icon (24px) paired with a `label-md` descriptive anchor beneath.

### Modular Cards
- 16px corner radius, `#FFFFFF` fill, 1px `#E2E8F0` border.
- **Navy Hero Account Card:** `#1B2A41` fill, containing live balance in `display-lg` white text, secondary masked balance toggles, quick deposit/transfer links, and embossed subtle grain or wave motif.

### Transaction List Tiles
- 64px fixed vertical height for seamless touch scanning.
- Left-aligned icon wrapper (40px circle, `#F1F5F9` fill), mid-section double-stack containing counterparty and timestamp (`body-md` bold / `body-sm` muted), right-aligned currency amount with tabular alignment (`+` green for inputs, `-` neutral dark for outputs).

### Chips & Filters
- Height: 32px. Shape: full pill (`9999px`). 
- Default state: `#FFFFFF` surface with `#E2E8F0` outline and `#64748B` typography.
- Active state: `#1B2A41` background, white `#FFFFFF` typography.

### Input Fields
- Minimum height 48px, 12px corner radius.
- Inactive: `#FFFFFF` fill with 1px `#E2E8F0` border.
- Focused: 1px `#F28C28` stroke accompanied by a subtle `#F28C28` focus ring (0 0 0 3px rgba(242, 140, 40, 0.15)).
- Text: `#0F172A` input string with permanent USD `$` anchor prefix where relevant.

### Bottom Navigation Bar
- Fixed bottom sheet, 64px height + safe area insets. White `#FFFFFF` surface with 1px `#E2E8F0` top border.
- Four target destinations: *Inicio*, *Cuentas*, *Divisas*, *Perfil*.
- Inactive item: `#64748B` icon with `label-sm` text. Active item: `#F28C28` icon and typography with a 4px dot marker indicator.