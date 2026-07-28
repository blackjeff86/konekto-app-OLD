# Template Compatibility Matrix

Last updated: 2026-07-27

Templates under analysis:

- Aura
- Bosque
- Elite
- Pulse
- Horizon

## Current Reality

The repository already contains all five white-label templates in `apps/konekto_mobile/lib/templates`, but the live guest app does not yet prove full end-to-end parity across the five templates.

What is true today:

- all five have Home implementations
- guest template selection exists in backend and portal
- allowed templates are enforced by plan preset in backend
- app loads selected template for Home
- the same pilot-safe guest flows converge into shared routed pages after leaving Home

What is not yet true:

- no shared compatibility checklist existed before this document
- not all routed guest surfaces are genuinely template-specific
- several template-only screens are disconnected demo artifacts
- loyalty/wallet support is inconsistent across templates

Task 9 validation reference:

- see [template-compatibility-validation-2026-07-27.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/template-compatibility-validation-2026-07-27.md:1) for the compatibility certification pass completed on July 27, 2026

## Runtime Architecture Status

### Fully wired today

- Home template selection
- template themes
- template choice restriction by plan preset

### Shared instead of per-template

- Services
- Bookings
- Profile
- Hotel info
- Notices
- My orders
- Stay bill

### Demo/disconnected template screens still present

- onboarding screens
- splash screens
- room service demo screens
- concierge chat demo screens
- extra directory screens

These should not be mistaken for production-ready parity.

## Matrix

| Scenario | Aura | Bosque | Elite | Pulse | Horizon | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Home loads with selected template | Sim | Sim | Sim | Sim | Sim | Backed by `template` in hotel config |
| Portal can select template | Sim | Sim | Sim | Sim | Sim | With plan restriction |
| Essential preset allows template | Sim | Sim | Nao | Nao | Nao | Backend-enforced |
| Premium preset allows template | Sim | Sim | Sim | Sim | Sim | Backend-enforced |
| Home uses same resolved backend hotel config | Sim | Sim | Sim | Sim | Sim | Pilot builds now target API-first truth path |
| Same real service flows proven | Sim | Sim | Sim | Sim | Sim | Shared routed pages after Home |
| Same real messaging flows proven | Sim | Sim | Sim | Sim | Sim | Shared notices/messages flow |
| Same real bookings/order flows proven | Sim | Sim | Sim | Sim | Sim | Shared bookings/order history flow |
| Loyalty screen exists | Nao | Nao | Sim | Sim | Sim | Current repo behavior |
| Wallet screen exists | Nao | Nao | Sim | Sim | Sim | Current repo behavior |
| Loyalty/wallet use real backend data | Nao | Nao | Nao | Nao | Nao | Current repo docs say mock data |

## Required Fixture Packs For Phase Validation

These fixtures are required for real template certification:

### Small hotel

- few services
- restaurant + tours only
- no promotions
- short content

### Mid-size hotel

- multiple services
- room service
- restaurant
- spa
- promotions
- messages
- medium content

### Resort

- many modules
- long text
- many images
- many orders and reservations

### Problem states

- missing image
- long text
- empty module
- no Wi-Fi info
- expired stay
- slow API
- unavailable API
- incomplete content

## Checklist To Be Executed In Next Delivery Phase

| Check | Aura | Bosque | Elite | Pulse | Horizon | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| No layout overflow on Home | Pendente | Pendente | Pendente | Pendente | Pendente | still needs visual QA pack |
| Long text remains readable | Pendente | Pendente | Pendente | Pendente | Pendente | still needs visual QA pack |
| Missing images show safe fallback | Pendente | Pendente | Pendente | Pendente | Pendente | still needs visual QA pack |
| Bottom nav remains functional | Certificado | Certificado | Certificado | Certificado | Certificado | same Module Engine resolution path |
| Disabled modules are hidden consistently | Certificado | Certificado | Certificado | Certificado | Certificado | same `enabledModules` path |
| Offline state is usable | Pendente | Pendente | Pendente | Pendente | Pendente | not certified in this pass |
| Error state is usable | Pendente | Pendente | Pendente | Pendente | Pendente | not certified in this pass |
| Expired stay state is handled | Certificado | Certificado | Certificado | Certificado | Certificado | shared guest auth / claim path |
| Same service dataset renders acceptably | Certificado | Certificado | Certificado | Certificado | Certificado | shared routed service surfaces |
| Same order flow works end-to-end | Certificado | Certificado | Certificado | Certificado | Certificado | shared bookings / order surfaces |

## Main Compatibility Risks

1. Home is still hand-authored by template, so visual parity depends on manual consistency.
2. Loyalty/wallet capability is asymmetric across templates.
3. Shared routed pages reduce pilot risk, but also mean the current app is not yet fully expression-rich per template.
4. Visual QA for long/empty/error states is still pending.

## Acceptance Threshold For Pilot

For pilot approval, the five templates should at minimum prove:

- same tenant can switch templates without losing module access
- same real room service flow works in all five
- same real restaurant flow works in all five
- same guest claim and stay loading works in all five
- same messaging and notices work in all five
- no template causes unusable layout under long/empty/error data

Current July 27, 2026 verdict:

- the first five acceptance points above are now certified at the runtime-path level
- the final visual-robustness point still needs dedicated manual QA before claiming full template parity
