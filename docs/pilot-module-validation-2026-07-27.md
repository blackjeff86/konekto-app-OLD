# Pilot Module Validation

Last updated: 2026-07-27

## Objective

Validate the July 2026 Sevvn pilot modules against real persisted runtime paths instead of catalog presence alone.

This document is the Task 8 evidence set for the 30-day pilot hardening plan.

## Validation Rule

A module is only treated as validated for the pilot when all of the following are true:

- it has a reachable guest or staff runtime flow
- it reads or writes persisted backend data
- the backend path is part of the active API stack, not asset/demo-only fallback
- the flow is consistent with the official pilot scope frozen on July 26, 2026

## Validated Modules

| Module | Runtime evidence | Persistence evidence | Verdict |
| --- | --- | --- | --- |
| `hotel_info` | Guest claim returns room, stay dates, hotel ID, and Wi-Fi data for the active stay | [guest claim route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/guest/claim/route.ts:1) reads `Guest`, `Stay`, `Room`, and `HotelContent.guestInfo` | Validated for pilot |
| `messages` | Guest/staff chat is reachable from app and portal flows | [guest messages route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/guest/messages/route.ts:1) and [staff stay messages route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/hotels/[hotelId]/stays/[stayId]/messages/route.ts:1) persist `StayMessage` rows | Validated for pilot |
| `room_service` | Guest can create orders; staff can list and advance them in portal ops | [orders route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/orders/route.ts:1) creates `Order` from persisted `ServiceItem`; service management is live in [services routes](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/hotels/[hotelId]/services/route.ts:1) | Validated for pilot |
| `restaurant` | Guest can reserve tables and interact with restaurant catalog; staff operates the same persisted service domain | [orders route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/orders/route.ts:1) creates hidden table reservation orders; [table availability route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/hotels/[hotelId]/services/[serviceId]/table-availability/route.ts:1) computes persisted capacity from `Order` + `RestaurantTableType` | Validated for pilot |
| `spa` | Available through the generic service model rather than a fake standalone screen | Persisted `Service` and `ServiceItem` records, module-gated through [service detail route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/hotels/[hotelId]/services/[serviceId]/route.ts:1) and created/managed through [services routes](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/hotels/[hotelId]/services/route.ts:1) | Validated for controlled pilot use |
| `tours` | Same real path as spa: generic service model, guest-facing service pages, persisted catalog | Uses the same persisted `Service` / `ServiceItem` stack as spa with live API reads and writes | Validated for controlled pilot use |
| `promotions` | Guest-facing promotions and staff coupon operations are both present in active stack | [promotions route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/promotions/route.ts:1) reads persisted `BrandContent`; [orders route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/orders/route.ts:1) revalidates persisted `Coupon` state server-side | Validated for controlled pilot use |

## Partially Validated Modules

| Module | What is real | What is still partial | Verdict |
| --- | --- | --- | --- |
| `home` | All five templates render active guest/session/module data and unread counters | Home composition is still template-led rather than a fully backend-driven presentation contract | Partial, keep in pilot with caution |
| `services` | Service catalog, items, module gating, staff CRUD, and guest reads all use persisted backend data | It is still an aggregator shell, not yet a fully normalized cross-template module contract | Partial but acceptable for pilot |
| `bookings` | Orders, table reservations, and stay bill data are all backed by persisted records | The module still groups heterogeneous domains instead of a clean reservation abstraction | Partial, pilot-safe only in controlled narrative |
| `profile` | Guest sees real room/session context and can access real stay-related data | The module is still mixed with optional wallet/loyalty affordances that are not pilot-ready | Partial, do not oversell |
| `basic_notifications` | Unread counts come from persisted `StayMessage` and `Order` state via [guest unread routes](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/guest/messages/unread-count/route.ts:1) and [guest unseen orders route](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/guest/orders/unseen-count/route.ts:1) | It is still a lightweight badge/notices layer rather than a richer notifications system | Partial but valid for pilot |

## Explicit Non-Pilot Counterexamples

These remain important because they are the clearest places where catalog presence would overstate reality.

| Module | Why it does not pass Task 8 validation |
| --- | --- |
| `digital_wallet` | Catalog says implemented, but the user-facing capability is still partial/demo-oriented and not a coherent pilot-safe financial module |
| `loyalty` | Catalog says implemented, but there is no pilot-safe persisted loyalty domain behind the screen-level affordance |
| `payments` | Payment domain exists through stay-bill payment APIs, but not as a finished standalone Sevvn module with cross-surface operational completeness |
| `events` | Generic service model could host it, but the catalog still marks it unimplemented and there is no validated pilot narrative for it |
| `concierge` | Template/demo UI exists, but there is no real backend module path |

## Pilot Verdict As Of July 27, 2026

### Strongest validated modules

- `hotel_info`
- `messages`
- `room_service`
- `restaurant`

### Valid for controlled pilot usage

- `spa`
- `tours`
- `promotions`

### Allowed in pilot, but must be described carefully

- `home`
- `services`
- `bookings`
- `profile`
- `basic_notifications`

## Operational Consequences

- Sales and partnership language should treat `room_service`, `restaurant`, `messages`, and `hotel_info` as the strongest proof points.
- `spa`, `tours`, and `promotions` are real enough to demonstrate, but only as controlled pilot capabilities.
- `home`, `services`, `bookings`, `profile`, and `basic_notifications` should stay in pilot language without claiming full product maturity.
- `digital_wallet`, `loyalty`, `payments`, `events`, and `concierge` should remain outside the official pilot-ready narrative.

## Source Pointers

- [module catalog](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/lib/module-catalog.ts:1)
- [module registry](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/lib/module-registry.ts:1)
- [module engine](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/lib/module-engine.ts:1)
- [pilot scope freeze](/abs/path/C:/ProjetosFlutter/konekto_app/docs/pilot-scope-freeze.md:1)
- [module readiness matrix](/abs/path/C:/ProjetosFlutter/konekto_app/docs/module-readiness-matrix.md:1)
