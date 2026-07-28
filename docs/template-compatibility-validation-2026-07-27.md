# Template Compatibility Validation

Last updated: 2026-07-27

## Objective

Validate whether the same pilot-safe guest scenarios remain usable across the five Sevvn guest templates:

- Aura
- Bosque
- Elite
- Pulse
- Horizon

This document is the Task 9 evidence set for the 30-day pilot hardening plan.

## Validation Method

This pass validates compatibility by tracing the active runtime architecture:

- how template selection is resolved
- which surfaces are actually template-specific
- which guest flows converge into shared routed pages
- which known asymmetries still prevent full parity claims

This is a code-and-runtime-path certification pass, not a visual QA screenshot pack.

## Core Architectural Finding

The five-template system is asymmetric by design today:

- **Home is template-specific**
- **most pilot-critical guest flows are shared after leaving Home**

That means pilot compatibility is much stronger than full template parity.

## Shared Runtime Evidence

### Template-specific only on Home

- [guest template registry](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/templates/guest_template_registry.dart:1) registers exactly five Home builders and five template themes
- [tenant_home_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/tenant_home_page.dart:1) resolves `tenantConfig['template']` and delegates only Home rendering to the selected template

### Shared routed guest flows after Home

From the same [tenant_home_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/tenant_home_page.dart:1):

- `services` always goes to shared [services_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/services_page.dart:1)
- `bookings` always goes to shared [bookings_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/bookings_page.dart:1)
- `profile` always goes to shared [profile_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/templates/shared/widgets/profile_page.dart:1)
- notices/messages always go to shared [notices_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/notices_page.dart:1)
- hotel info always goes to shared [hotel_info_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/hotel_info_page.dart:1)
- order history always goes to shared [my_orders_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/my_orders_page.dart:1)
- stay bill always goes to shared [stay_bill_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/stay_bill_page.dart:1)

## Certified Shared Pilot Scenarios

| Scenario | Aura | Bosque | Elite | Pulse | Horizon | Result |
| --- | --- | --- | --- | --- | --- | --- |
| Guest claim loads same tenant/session data | Sim | Sim | Sim | Sim | Sim | Certified |
| Home loads selected template with real guest/session/module params | Sim | Sim | Sim | Sim | Sim | Certified |
| Home can navigate to Services | Sim | Sim | Sim | Sim | Sim | Certified |
| Same real service catalog flow is used after leaving Home | Sim | Sim | Sim | Sim | Sim | Certified |
| Same room service backend path is reachable | Sim | Sim | Sim | Sim | Sim | Certified |
| Same restaurant reservation/backend path is reachable | Sim | Sim | Sim | Sim | Sim | Certified |
| Same notices/messages flow is reachable | Sim | Sim | Sim | Sim | Sim | Certified |
| Same order history / bookings shell is reachable | Sim | Sim | Sim | Sim | Sim | Certified |
| Same hotel info / Wi-Fi flow is reachable | Sim | Sim | Sim | Sim | Sim | Certified |
| Same bottom-nav resolution logic is used | Sim | Sim | Sim | Sim | Sim | Certified |

## Compatibility Limits Still Present

| Topic | Aura | Bosque | Elite | Pulse | Horizon | Result |
| --- | --- | --- | --- | --- | --- | --- |
| Loyalty screen exists | Nao | Nao | Sim | Sim | Sim | Not pilot-safe parity |
| Wallet screen exists | Nao | Nao | Sim | Sim | Sim | Not pilot-safe parity |
| Loyalty/wallet use real backend data | Nao | Nao | Nao | Nao | Nao | Not certified |
| Template-specific room service demo screens are runtime-connected | Nao | Nao | Nao | Nao | Nao | Demo only |
| Template-specific concierge demo screens are runtime-connected | Nao | Nao | Nao | Nao | Nao | Demo only |
| Fully template-native Services/Bookings/Profile surfaces exist | Nao | Nao | Nao | Nao | Nao | Shared-theme only |

## Pilot Compatibility Verdict

### Certified for pilot-safe shared scenarios

- all five templates can participate in the same pilot dataset for:
- guest claim
- Home loading
- module-driven bottom navigation
- services access
- room service flows
- restaurant flows
- notices/messages
- order history
- hotel info / Wi-Fi

### Not certified for full template parity

- loyalty
- wallet
- concierge
- template-specific room service demos
- template-specific directory/demo surfaces

## Consequences For Pilot Messaging

- It is accurate to say the same pilot hotel can switch among the five templates without losing the core operational guest flows.
- It is not accurate to say every guest surface is fully bespoke and parity-validated per template.
- The five templates should be described as five visual identities over the same pilot-safe operational guest stack.

## Recommendation For Task 10

Public/internal claims should now distinguish:

- **five-template compatibility for core pilot flows**: true
- **full feature parity on every template-specific surface**: not true

## Source Pointers

- [template compatibility matrix](/abs/path/C:/ProjetosFlutter/konekto_app/docs/template-compatibility-matrix.md:1)
- [pilot module validation](/abs/path/C:/ProjetosFlutter/konekto_app/docs/pilot-module-validation-2026-07-27.md:1)
- [guest template registry](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/templates/guest_template_registry.dart:1)
- [tenant home page](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/tenant_home_page.dart:1)
