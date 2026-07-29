---
name: Bosque
colors:
  surface: '#fbf9f5'
  surface-dim: '#dbdad6'
  surface-bright: '#fbf9f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3ef'
  surface-container: '#efeeea'
  surface-container-high: '#eae8e4'
  surface-container-highest: '#e4e2de'
  on-surface: '#1b1c1a'
  on-surface-variant: '#424844'
  inverse-surface: '#30312e'
  inverse-on-surface: '#f2f0ed'
  outline: '#727973'
  outline-variant: '#c2c8c2'
  surface-tint: '#496455'
  primary: '#173124'
  on-primary: '#ffffff'
  primary-container: '#2d4739'
  on-primary-container: '#98b5a3'
  inverse-primary: '#b0cdbb'
  secondary: '#77574b'
  on-secondary: '#ffffff'
  secondary-container: '#ffd4c4'
  on-secondary-container: '#7a594d'
  tertiary: '#422401'
  on-tertiary: '#ffffff'
  tertiary-container: '#5c3a13'
  on-tertiary-container: '#d5a474'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ccead6'
  primary-fixed-dim: '#b0cdbb'
  on-primary-fixed: '#062014'
  on-primary-fixed-variant: '#324c3e'
  secondary-fixed: '#ffdbce'
  secondary-fixed-dim: '#e7beae'
  on-secondary-fixed: '#2c160c'
  on-secondary-fixed-variant: '#5d4034'
  tertiary-fixed: '#ffdcbd'
  tertiary-fixed-dim: '#f0bd8b'
  on-tertiary-fixed: '#2c1600'
  on-tertiary-fixed-variant: '#623f18'
  background: '#fbf9f5'
  on-background: '#1b1c1a'
  surface-variant: '#e4e2de'
typography:
  headline-xl:
    fontFamily: Literata
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Literata
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.3'
  headline-lg-mobile:
    fontFamily: Literata
    fontSize: 28px
    fontWeight: '600'
    lineHeight: '1.3'
  headline-md:
    fontFamily: Literata
    fontSize: 24px
    fontWeight: '500'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.2'
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
  lg: 48px
  xl: 80px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 64px
---

## Brand & Style
The design system is rooted in the concept of **Biophilic Design**, aiming to bridge the gap between digital interfaces and the natural world. The brand personality is warm, nurturing, and professional—evoking the feeling of a sun-drenched forest clearing or a high-end eco-retreat. It prioritizes comfort and tranquility over clinical efficiency.

The visual style is a blend of **Modern Minimalism** and **Tactile Organicism**. It leverages high-quality nature photography, generous whitespace (mimicking open air), and soft, diffused visual elements to reduce cognitive load and create a sense of serenity for the user.

## Colors
The palette is derived from the natural forest floor and canopy. 
- **Primary (Forest Green):** Used for key actions and brand presence, providing a stable, grounding foundation.
- **Secondary (Wood Brown):** Used for accents and earthy highlights to add warmth.
- **Tertiary (Ochre/Earth):** A soft accent color for call-outs or highlights.
- **Neutral (Soft Cream):** The primary background color, replacing harsh whites to reduce eye strain and enhance the "cozy" atmosphere.
- **Text (Bark Charcoal):** A very dark, warm brown-grey for high legibility without the starkness of pure black.

## Typography
This design system employs a sophisticated pairing of a scholarly serif and a friendly sans-serif. 
- **Headlines (Literata):** Chosen for its organic terminals and high readability. It feels authoritative yet human. Use it for all major headings to establish a narrative, "book-like" flow.
- **Body & UI (Plus Jakarta Sans):** Its soft, rounded letterforms mirror the "roundedness" of the UI components. It ensures that even data-heavy sections feel approachable and modern.

## Layout & Spacing
The layout follows a **Fluid Grid** model with an emphasis on wide margins to create "breathing room." 
- **Desktop:** Use a 12-column grid with 24px gutters. Page margins are generous (64px) to center the content and prevent it from feeling overwhelming.
- **Mobile:** Transition to a 4-column grid with 16px margins. 
- **Rhythm:** Spacing follows a base-8 scale. Larger gaps (48px+) should be used between sections to maintain the airy, tranquil feel of the design.

## Elevation & Depth
Depth is conveyed through **Ambient Shadows** and **Tonal Layering**. 
- **Shadows:** Avoid pure black or grey shadows. Shadows in this design system should be tinted with the Secondary Wood Brown (e.g., #8C6A5D at 10-15% opacity) and feature a high blur radius to appear soft and natural.
- **Surfaces:** Use subtle shifts in background color (e.g., moving from the Cream base to a slightly darker "Almond" tone) to define stacked elements like cards or modals.
- **Glassmorphism:** Use sparingly for navigation overlays, using a heavy backdrop blur (20px+) to simulate frost or morning mist.

## Shapes
The shape language is organic and soft. Level 2 roundedness (0.5rem base) ensures that there are no sharp, aggressive corners in the UI. 
- **Standard UI (Buttons, Inputs):** 8px (0.5rem).
- **Containers (Cards, Modals):** 16px (1rem).
- **Specialty Elements (Chips, Search Bars):** 24px+ (1.5rem) to create a pill-shaped effect that feels smooth to the touch.

## Components
- **Buttons:** Primary buttons use the Forest Green background with Cream text. They should have a subtle inner glow or soft bottom shadow to look "pressable" and tactile.
- **Cards:** Use a "Surface" approach—very subtle borders (#E5E0D8) or soft brown-tinted shadows. Images within cards should always have rounded corners to match the container.
- **Inputs:** Fields should have a light cream background, slightly darker than the page base, to create a "recessed" feel. The focus state uses a 2px Forest Green border.
- **Chips:** Highly rounded (pill-shaped) with low-contrast backgrounds. Used for categories like "Mountain," "Forest," or "Riverside."
- **Lists:** Use generous vertical padding between list items (16px+) and soft dividers that fade out toward the edges.
- **Photography:** All imagery should feature soft, natural lighting (Golden Hour) and high-quality textures. Avoid saturated, artificial-looking stock photos.