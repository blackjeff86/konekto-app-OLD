---
name: Elevated Hospitality Suite
colors:
  surface: '#fdf7ff'
  surface-dim: '#ded8e0'
  surface-bright: '#fdf7ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f8f2fa'
  surface-container: '#f2ecf4'
  surface-container-high: '#ece6ee'
  surface-container-highest: '#e6e0e9'
  on-surface: '#1d1b20'
  on-surface-variant: '#494551'
  inverse-surface: '#322f35'
  inverse-on-surface: '#f5eff7'
  outline: '#7a7582'
  outline-variant: '#cbc4d2'
  surface-tint: '#6750a4'
  primary: '#4f378a'
  on-primary: '#ffffff'
  primary-container: '#6750a4'
  on-primary-container: '#e0d2ff'
  inverse-primary: '#cfbcff'
  secondary: '#63597c'
  on-secondary: '#ffffff'
  secondary-container: '#e1d4fd'
  on-secondary-container: '#645a7d'
  tertiary: '#765b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c9a74d'
  on-tertiary-container: '#503d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e9ddff'
  primary-fixed-dim: '#cfbcff'
  on-primary-fixed: '#22005d'
  on-primary-fixed-variant: '#4f378a'
  secondary-fixed: '#e9ddff'
  secondary-fixed-dim: '#cdc0e9'
  on-secondary-fixed: '#1f1635'
  on-secondary-fixed-variant: '#4b4263'
  tertiary-fixed: '#ffdf93'
  tertiary-fixed-dim: '#e7c365'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#594400'
  background: '#fdf7ff'
  on-background: '#1d1b20'
  surface-variant: '#e6e0e9'
typography:
  display-lg:
    fontFamily: Libre Caslon Text
    fontSize: 48px
    fontWeight: '400'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Work Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 80px
---

## Brand & Style
This design system is engineered for a premium white-label hospitality platform, balancing operational efficiency with high-end guest experiences. The brand personality is **composed, anticipatory, and prestigious**. It caters to two distinct market tiers:

*   **Essential Tier:** Focuses on clarity, modern efficiency, and approachable luxury.
*   **Premium Tier:** Emphasizes "Quiet Luxury," sensory depth, and bespoke service.

The design style is a hybrid of **Modern Minimalism** and **Tactile Sophistication**. We utilize generous whitespace to evoke a sense of calm, while employing high-quality typography and subtle elevation to guide the guest's journey from digital check-in to concierge services.

## Colors
The palette is structured to transition from the crisp, functional tones of the Essential tier to the rich, atmospheric tones of the Premium tier.

*   **Aura & Horizon:** Utilize airy, light-filled palettes to mimic the feeling of open lobbies and seaside resorts.
*   **Bosque:** Uses organic earth tones to ground the user in a wellness or nature-focused environment.
*   **Élite:** Employs muted metallics and off-whites to signify "Quiet Luxury."
*   **Pulse:** A high-tech dark mode execution for urban boutique hotels, using gold accents for selective focus.

## Typography
The typographic system utilizes a dual-engine approach to distinguish between tiers:

1.  **Modern Sans-Serif (Plus Jakarta Sans):** Used for functional clarity across all themes. It provides a friendly but professional face for check-in flows and room service menus.
2.  **Luxury Serif (Libre Caslon Text):** Introduced in **Élite** and **Bosque** themes for headlines to evoke a heritage, editorial feel.

Maintain a strict vertical rhythm. Use **label-caps** for small metadata like "Room Number" or "Status" to ensure legibility at small sizes without cluttering the UI.

## Layout & Spacing
The system is built on a **rigid 8px grid** to ensure consistency across the white-label ecosystem. 

*   **Grid:** Use a 12-column grid for desktop and a 4-column grid for mobile.
*   **Safe Areas:** Mobile views must maintain a 20px side margin. 
*   **Touch Targets:** All interactive elements (buttons, list items) must have a minimum height of 48px.
*   **Modular Rhythm:** Components like Room Service cards use `spacing.md` for internal padding and `spacing.sm` for stack spacing to create a clean, organized "lifestyle" look.

## Elevation & Depth
Elevation is used selectively to signify hierarchy and temporary states (modals, sheets).

*   **Essential Tier (Aura, Bosque):** Uses low-contrast outlines (1px solid borders) and flat surfaces to maintain a clean, breezy feel.
*   **Premium Tier (Élite, Pulse, Horizon):** Employs **Ambient Shadows**. Shadows should be extra-diffused with a low opacity (8-12%) and slightly tinted with the primary brand color to avoid a "dirty" grey look.
*   **Surfaces:** Use Tonal Layers (e.g., a background at 100% white and a surface card at 95% grey/beige) to create depth without relying on heavy dropshadows.

## Shapes
The shape language is primarily **Rounded (0.5rem base)**. 

*   **Cards & Modals:** Use `rounded-lg` (1rem) to soften the interface and make it feel more welcoming.
*   **Buttons:** Standardize on `rounded-lg` for most themes. In **Pulse**, consider sharp corners or minimal rounding (0.25rem) to reinforce the "Tech/Modern" aesthetic.
*   **Bottom Sheets:** Top corners should always be `rounded-xl` (1.5rem) to create a soft, tactile "drawer" effect.

## Components
Consistent styling across all five themes ensures the white-label platform remains functional regardless of the aesthetic skin.

*   **Buttons:** 
    *   *Primary:* Solid fill using `primary_color`. 
    *   *Secondary:* Outlined or soft-tinted background. 
    *   *Ghost:* Text-only with high-contrast for "Cancel" or secondary actions.
*   **Hospitality Cards:**
    *   *Service Card:* Image-led with a 16px overlay for the title.
    *   *Promo Card:* Uses the theme's secondary color for the background to stand out from the main grid.
*   **Navigation:** 
    *   *Bottom Bar:* Use for mobile primary navigation (Home, Keys, Concierge, Profile). 
    *   *Top Bar:* Minimalist, containing only the property logo and the "Notifications" bell.
*   **Specialty Modules:**
    *   *Digital Key:* A high-visibility, center-aligned component with a unique pulsing animation.
    *   *Concierge Chat:* Bubbles use `surface` colors for the agent and `primary` for the guest, using `body-sm` typography.
    *   *Check-in/out:* A linear progress indicator at the top of the screen to reduce friction during high-stress travel moments.