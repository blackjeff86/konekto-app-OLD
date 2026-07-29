# Implementation Plan: Sevvn Guest TypeScript Migration

## Overview

This plan migrates the Sevvn guest app from Flutter Web (`apps/konekto_mobile`) to a TypeScript web app that behaves as a thin UX shell over the platform backend. The new app should render branding, templates, navigation, and module-driven surfaces from real hotel configuration and enabled modules, without relying on precompiled Flutter bundles or local asset-mode behavior for the production path.

The immediate goal is not a full multi-app rewrite. The first target is `sevvn-guest`, because it is already live, directly guest-facing, and currently carries the highest operational friction: Flutter web build coupling, mixed template behavior, asset/runtime fallback complexity, and hard-to-ship visual corrections.

## Architecture Decisions

- Build the new guest app in TypeScript on the same stack family already used by `apps/sevvn_portal_next` and `apps/sevvn_site_next`: Next.js + React + TypeScript.
- Treat the API as the single runtime source of truth. The guest app must render from:
  - `GET /api/hotels/:hotelId`
  - module catalog / resolved enabled modules
  - services and service details
  - guest claim / guest-authenticated endpoints
- Keep templates as a presentation layer only. Template selection controls theme, layout, and component styling, not business rules.
- Reuse existing TypeScript contracts and patterns wherever possible:
  - data fetching and mutations from `apps/sevvn_portal_next`
  - hotel configuration contracts from `apps/sevvn_api`
  - brand and page conventions from `apps/sevvn_site_next`
- Do not block on full feature parity before shipping the first vertical slice. The migration should happen by real guest-facing slices.
- Keep the existing Flutter app alive until the TypeScript guest app has a validated replacement path for the pilot flow.
- Treat Sevvn as the hotel experience core, not as a mandatory replacement for PMS, POS, ERP, channel manager, or middleware tools already used by the property.
- Support three first-class operating modes from the start:
  - standalone mode, where the hotel runs Sevvn without any external integration;
  - hybrid mode, where some modules stay fully inside Sevvn while others sync with PMS, POS, ERP, channel manager, or middleware;
  - connected mode, where Sevvn ingests and emits most operational data through authenticated integration adapters, inbound sync routes, and signed outbound webhooks.
- Keep tenant isolation as a non-negotiable rule:
  - guest-facing reads must derive `hotelId` from the authenticated guest context;
  - staff-facing writes must derive hotel scope from the authenticated staff context;
  - integration flows must derive hotel scope from the integration credential/key, never from a free client-supplied hotel identifier alone.
- Keep templates and frontend shells thin. Business rules, module gating, and cross-system reconciliation belong to the API/core layer so the same model works for both standalone hotels and deeply integrated enterprise properties.

## Current State Summary

- Backend module resolution already exists in TypeScript (`apps/sevvn_api/lib/module-engine.ts` and related files).
- Hotel portal already exposes TypeScript patterns for:
  - hotel configuration
  - modules
  - branding
  - services management
- Flutter guest app already proves the intended product behavior, but is operationally fragile because Vercel serves a prebuilt `build/web` bundle.
- The live guest flow already depends on:
  - guest claim
  - hotel config
  - services list and service detail
  - orders / minibar / reservations
  - template-aware home

## Migration Target

The TypeScript guest app should become:

- a web app deployed independently on Vercel;
- driven by hotel identity + guest context;
- module-aware in navigation and content rendering;
- template-aware in visual presentation;
- free from local asset-mode reliance in the production path;
- ready to consume a hotel-scoped core that works with or without external integrations.

## Integration Principles

- Sevvn remains usable even when a hotel does not connect any existing system. In that case, hotel staff manage rooms, stays, services, pricing, and guest operations directly in Sevvn.
- When integrations exist, Sevvn should orchestrate guest-facing experiences from normalized platform data instead of exposing raw third-party system shapes to the app shell.
- Hybrid operation is the expected real-world default for many hotels: one module may remain fully managed inside Sevvn while another module syncs with an external operational system.
- External systems should plug into Sevvn through controlled boundaries:
  - inbound sync endpoints for reservations, menus, catalog entities, and operational records;
  - outbound signed webhooks for orders and operational events;
  - future connector/adaptor layers for vendor-specific PMS, POS, ERP, or middleware mappings.
- The guest app must stay agnostic to which upstream system originated the data. It should only consume Sevvn contracts already normalized for one authenticated hotel context.
- Large-hotel connector work must not degrade the standalone path for smaller hotels. Both paths should use the same module and service contracts downstream.
- Restaurant module requirements must support more than one reservation operating model:
  - booking by party size (`mesa para quantas pessoas`);
  - booking by explicit table type/inventory (`mesas de 2`, `mesas de 4`, etc.);
  - hybrid exposure where Sevvn can infer the best table but the hotel may still expose table-type detail.
- Restaurant module requirements must also support configurable menu visibility:
  - visible with prices;
  - visible without prices;
  - hidden while table booking remains enabled.
- Restaurant module requirements must also expose operational reservation policy:
  - waitlist enabled/disabled;
  - optional waitlist capacity;
  - reservation expiration window so the guest knows how long the table is held.
- Reservation notifications should not be modeled as restaurant-only delivery logic.
  - `restaurant` owns reservation state transitions and policy;
  - `basic_notifications` / future communication surfaces own message delivery;
  - restaurant reservation events should publish into the communication layer for confirmation, cancellation, reschedule, and expiry-warning notifications.

## Task List

### Phase 1: Foundation And Host App

- [ ] Task 1: Define the new app location and deployment shape.
- Status:
  - Completed on July 28, 2026.
  - Repository path chosen: `apps/sevvn_guest_next`.
  - Deployment intent: independent Vercel app replacing the current `sevvn-guest` runtime after cutover readiness.
  - Decision target: create a dedicated TypeScript app for guest experience instead of extending portal/site apps.
  - Acceptance criteria:
    - [ ] The repository location is fixed.
    - [ ] The runtime/deploy model is documented.
    - [ ] The app naming and Vercel target are aligned with `sevvn-guest`.
  - Verification:
    - [ ] Plan reviewed against current apps layout.
    - [ ] No ambiguity remains about where guest TypeScript code will live.
  - Dependencies: None
  - Files likely touched:
    - `tasks/plan-sevvn-guest-typescript-migration.md`
    - `tasks/todo-sevvn-guest-typescript-migration.md`
  - Estimated scope: Small

- [ ] Task 2: Scaffold the new TypeScript guest app with shared repo conventions.
- Status:
  - Completed on July 28, 2026.
  - Minimal Next.js app scaffolded with build, lint, and typecheck scripts.
  - Verified with `npx tsc --noEmit` and `npm run build`.
  - Acceptance criteria:
    - [ ] New app boots with Next.js + TypeScript.
    - [ ] Basic lint/build scripts exist.
    - [ ] The app can be deployed independently.
  - Verification:
    - [ ] `npm run build`
    - [ ] `npx tsc --noEmit`
  - Dependencies: Task 1
  - Files likely touched:
    - `apps/sevvn_guest_ts/package.json` or equivalent final path
    - app scaffold files
  - Estimated scope: Medium

- [ ] Task 3: Extract and normalize guest API contracts for TypeScript consumption.
- Status:
  - Completed on July 28, 2026 for the first migration slice.
  - Added typed guest contracts plus API clients for claim, hotel config, services list, and service detail.
  - This slice now also establishes the architectural boundary that the guest shell consumes normalized Sevvn contracts, regardless of whether hotel data was entered directly in Sevvn or synchronized from an external system.
  - Acceptance criteria:
    - [ ] Guest-facing hotel config, services, guest claim, and orders contracts are typed.
    - [ ] No TypeScript screen depends on ad hoc `any` payloads for core guest data.
    - [ ] Reusable API client primitives exist for the guest app.
  - Verification:
    - [ ] `npx tsc --noEmit`
    - [ ] Contract smoke tests or parser tests pass
  - Dependencies: Task 2
  - Files likely touched:
    - guest app `lib/api/*`
    - shared type files if extracted
  - Estimated scope: Medium

### Checkpoint: Foundation

- [ ] New app exists and builds cleanly.
- [ ] Core backend contracts are typed.
- [ ] We can start building real guest-facing slices without Flutter dependencies.

### Phase 2: Template System And Shell

- [ ] Task 4: Build the guest shell architecture in TypeScript.
  - Acceptance criteria:
    - [ ] App shell supports guest session context, hotel context, and routing.
    - [ ] Bottom navigation and section routing are driven by enabled modules.
    - [ ] Template selection is read from hotel config, not hardcoded.
    - [ ] Guest-facing hotel context is always derived from the authenticated guest session, never from a free hotel selector or untrusted URL state.
  - Verification:
    - [ ] Build succeeds
    - [ ] Manual check: shell renders with mocked hotel config
  - Dependencies: Task 3
  - Files likely touched:
    - guest app shell/layout/router files
  - Estimated scope: Medium

- [ ] Task 5: Port the five Sevvn guest templates into a TypeScript theme/layout system.
  - Acceptance criteria:
    - [ ] Aura, Bosque, Elite, Pulse, and Horizon exist as template definitions.
    - [ ] Shared tokens and per-template overrides are separated cleanly.
    - [ ] Home and shared surfaces can consume the same template system.
  - Verification:
    - [ ] Build succeeds
    - [ ] Manual visual review against current Sevvn template intent
  - Dependencies: Task 4
  - Files likely touched:
    - guest app template/theme files
  - Estimated scope: Large

- [ ] Task 6: Port the authenticated guest claim/session bootstrap flow.
  - Acceptance criteria:
    - [ ] Access code claim works in the TypeScript app.
    - [ ] Guest token persistence and logout are implemented.
    - [ ] Hotel and guest context load reliably after claim.
  - Verification:
    - [ ] Manual check: claim flow works end to end against API
    - [ ] Build succeeds
  - Dependencies: Task 3
  - Files likely touched:
    - guest auth/session files
    - claim page
  - Estimated scope: Medium

### Checkpoint: Shell

- [ ] Guest can claim access and enter the new shell.
- [ ] Correct hotel template loads from backend config.
- [ ] Navigation is module-aware.

### Phase 3: Core Vertical Slices

- [ ] Task 7: Ship the Home slice in TypeScript.
  - Acceptance criteria:
    - [ ] Home uses real hotel branding, template, room, and Wi-Fi data.
    - [ ] Notice/history/service shortcuts use live routes.
    - [ ] Home no longer depends on Flutter-only presentation logic.
  - Verification:
    - [ ] Manual check with a real hotel/guest record
    - [ ] Build succeeds
  - Dependencies: Tasks 5 and 6
  - Files likely touched:
    - home route/components
  - Estimated scope: Medium

- [ ] Task 8: Ship the Services directory slice in TypeScript.
  - Acceptance criteria:
    - [ ] Services list renders from live API data.
    - [ ] Service cards support real images and grouping.
    - [ ] Services screen uses the active Sevvn template language instead of a fixed fallback style.
  - Verification:
    - [ ] Manual check with real services data
    - [ ] Build succeeds
  - Dependencies: Tasks 5 and 6
  - Files likely touched:
    - services route/components
  - Estimated scope: Medium

- [ ] Task 9: Ship service detail flows for room service, minibar, and reservation-capable services.
  - Acceptance criteria:
    - [ ] Item listing works for service details.
    - [ ] Minibar flow works.
    - [ ] Reservation/order entry flows hit real endpoints.
    - [ ] Service actions are prepared to work against normalized Sevvn modules regardless of standalone or externally integrated hotel operation.
  - Verification:
    - [ ] Manual check across representative services
    - [ ] Build succeeds
  - Dependencies: Task 8
  - Files likely touched:
    - service detail pages
    - order/reservation interaction files
  - Estimated scope: Large

### Checkpoint: Core Guest Flow

- [ ] Claim → Home → Services → Service Detail works end to end.
- [ ] The production path is API-first and TypeScript-native.
- [ ] The app is usable for one representative pilot hotel.

### Phase 4: Secondary Surfaces And Replacement Readiness

- [ ] Task 10: Port bookings, notices/messages, profile, and stay-bill surfaces.
  - Acceptance criteria:
    - [ ] Secondary tabs are no longer dependent on Flutter.
    - [ ] Guest can complete the major self-service journey inside the TypeScript app.
  - Verification:
    - [ ] Manual regression pass
    - [ ] Build succeeds
  - Dependencies: Task 9
  - Files likely touched:
    - bookings/notices/profile/stay-bill routes
  - Estimated scope: Large

- [ ] Task 11: Align portal/admin links and QR entrypoints to the new guest app.
  - Acceptance criteria:
    - [ ] Generated guest URLs and QR flows point to the TypeScript guest app.
    - [ ] No live production flow depends on the Flutter guest URL for newly created stays.
  - Verification:
    - [ ] Manual check from hotel portal branding/reception flow
  - Dependencies: Task 10
  - Files likely touched:
    - `apps/sevvn_portal_next/lib/guestAppConfig.ts`
    - related QR/branding pages
  - Estimated scope: Small

- [ ] Task 12: Execute cutover readiness audit and de-risk Flutter retirement.
  - Acceptance criteria:
    - [ ] Remaining Flutter-only capabilities are explicitly listed.
    - [ ] Replacement readiness is documented.
    - [ ] A cutover/revert plan exists.
  - Verification:
    - [ ] Written audit reviewed
  - Dependencies: Task 11
  - Files likely touched:
    - `docs/*`
    - `tasks/*`
  - Estimated scope: Medium

### Checkpoint: Replacement Ready

- [ ] TypeScript guest app covers the intended pilot path.
- [ ] Guest entrypoints can be switched safely.
- [ ] Flutter retirement can be planned from evidence, not assumption.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Flutter and TypeScript guest apps drift during migration | High | Move by vertical slices and validate against one shared backend truth |
| Template migration becomes a one-to-one visual rewrite with duplicated code | High | Build shared tokens/shell first, then port templates into the same system |
| Module-driven routing logic diverges from backend rules | High | Consume backend-resolved modules instead of reimplementing plan logic in frontend |
| Replacing guest URLs too early breaks hotel operations | High | Delay cutover until claim-to-service flow is proven end to end |
| Migration scope expands into portal/admin rewrite at the same time | Medium | Limit this plan to `sevvn-guest` first and treat other apps as separate tracks |
| Enterprise integrations leak one hotel's data into another hotel context | High | Derive tenant scope from guest token, staff token, or integration credential on every request, and keep frontend hotel state read-only from authenticated context |
| External-system support makes small-hotel setup too complex | Medium | Preserve a complete standalone operating mode where Sevvn is the only system needed |

## Open Questions

- What should be the final app path/name in the repo for the TypeScript guest app?
- Do we want to reuse components/utilities from `apps/sevvn_portal_next` directly, or only copy patterns/contracts?
- Should the first production cutover replace `sevvn-guest.vercel.app` directly, or use a rehearsal URL first?

## Essential Execution Track

This track defines the recommended delivery order for the `essential` plan so Sevvn reaches a stable, sellable, and secure baseline quickly before moving into template-by-template frontend refinement.

### Essential Scope Today

The current `essential` preset includes:

- Core modules:
  - `home`
  - `hotel_info`
  - `services`
  - `bookings`
  - `messages`
  - `profile`
  - `basic_notifications`
- Hospitality modules:
  - `room_service`
  - `restaurant`
  - `tours`
  - `concierge`

Important note:

- `concierge` is present in the commercial preset but is still `implemented: false` in the module catalog as of July 28, 2026.
- This means `essential` must be treated in two layers:
  - `essential operational baseline`: only modules that are both included in the preset and actually implemented.
  - `essential commercial completion`: the same baseline plus delivery of `concierge`.

### Essential Baseline Strategy

Recommended order:

1. Stabilize `essential` backend/core modules first.
2. Validate standalone, hybrid, and integrated behavior on those modules.
3. Only after the backend/module contracts are stable, adapt the `essential` templates one by one in TypeScript.
4. Only after `essential` is operationally consistent, expand the same model into `premium` modules.

Why this order:

- It reduces risk by shrinking the first production surface.
- It forces business rules, isolation, and operational flows to mature before visual polishing.
- It prevents template work from being wasted on modules whose contracts are still moving.

### Essential Delivery Order

#### Wave 1: Core Identity And Safe Navigation

Modules:

- `home`
- `hotel_info`
- `services`
- `bookings`
- `profile`

Goal:

- Guarantee claim, authenticated guest context, hotel-scoped rendering, and module-aware navigation.
- These modules form the shell and must be trustworthy before adding richer operational flows.

Completion criteria:

- Claim flow derives hotel context only from authenticated guest access.
- Home renders real branding, room, and Wi-Fi data.
- Services and bookings entrypoints reflect only enabled modules for that hotel.
- Profile and booking surfaces show only guest-scoped data.

#### Wave 2: Core Communication Layer

Modules:

- `messages`
- `basic_notifications`

Goal:

- Close the communication loop between hotel staff and guest.
- Use `basic_notifications` as the transversal communication surface for operational state changes.

Current status:

- `messages` already exists in the legacy operational path.
- `basic_notifications` is now officially modeled and connected to restaurant reservation lifecycle events.

Completion criteria:

- Guest can read staff chat/messages safely within the same hotel/stay.
- Guest can read, count, and mark notifications as read.
- Notification delivery logic is reusable by other `essential` modules, not restaurant-specific.

#### Wave 3: Revenue And Fulfillment

Modules:

- `room_service`
- `restaurant`

Goal:

- Deliver the two most commercially meaningful hospitality modules in `essential`.
- Finish the standalone + hybrid + integrated operational model on real hospitality flows.

Current status:

- `room_service` already has guest ordering and minibar-adjacent operational flows.
- `restaurant` now has:
  - table booking modes
  - table type inventory
  - waitlist support
  - reservation expiry policy
  - queue operations in portal/backend
  - notification hooks through `basic_notifications`

Completion criteria:

- Staff and guest flows work safely with hotel-scoped data.
- Standalone operation works with no external system.
- Hybrid operation works when some data stays in Sevvn and some comes from an external system.
- Integration boundaries remain normalized so the guest shell never consumes raw upstream system shapes.

#### Wave 4: Experience Expansion Inside Essential

Modules:

- `tours`

Goal:

- Reuse the already established scheduling/booking architecture from restaurant and other reservation-capable services.
- Make `tours` the final implemented module needed to close the currently real `essential` hospitality baseline.

Completion criteria:

- Availability, capacity, scheduling, and booking status follow the same secure tenant-scoped model used elsewhere.
- No bespoke logic bypasses the normalized Sevvn contracts.

#### Wave 5: Essential Commercial Completion

Modules:

- `concierge`

Goal:

- Close the gap between what the `essential` preset promises commercially and what is truly implemented.

Important note:

- This should come after the core baseline, not before.
- Concierge is valuable, but it should sit on top of a stable communication and request-handling foundation instead of becoming an early exception path.

Completion criteria:

- `concierge` is marked `implemented: true`.
- It has registry/config support if needed.
- It uses the same communication and operational safeguards already established in the baseline.

### Practical Next-Step Sequence

After the work already completed up to July 28, 2026, the recommended immediate sequence is:

1. Audit `essential` module-by-module and mark each one as:
   - operationally stable
   - partially stable
   - planned only
2. Finish hardening the `room_service` operational model using the same tenant-isolated and notification-aware standards already applied to restaurant.
3. Finish the `tours` module using the normalized scheduling and booking foundation.
4. Deliver `concierge` so the commercial preset matches real platform capability.
5. Start template refactoring for `essential` in TypeScript, one template at a time:
   - `aura`
   - `bosque`

### Definition Of Done For Essential

`Essential` should only be considered truly complete when:

- every `essential` module either works end to end or is explicitly removed from the commercial preset;
- standalone mode works without mandatory external systems;
- hybrid mode works without leaking cross-hotel data;
- communication flows (`messages` + `basic_notifications`) are shared infrastructure, not one-off behavior;
- at least one TypeScript guest template is fully aligned with the stable `essential` module contracts;
- the second `essential` template is adapted without changing backend business rules.

