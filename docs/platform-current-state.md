# Platform Current State

Last updated: 2026-07-26

## Scope

This document captures the actual current state of the repository before any further platform implementation work. It reflects the codebase as found in:

- `apps/sevvn_api`
- `apps/sevvn_portal_next`
- `apps/konekto_mobile`
- `apps/sevvn_admin`
- `apps/konekto_site`
- `apps/sevvn_site_next`

The product is still named `Konekto` in code, but this analysis treats it as the current codebase that would need to evolve into the Sevvn platform.

## 1. Current Architecture Diagram

```text
                           ┌──────────────────────────┐
                           │   apps/sevvn_admin     │
                           │ Flutter platform admin   │
                           └────────────┬─────────────┘
                                        │ HTTP
                                        ▼
┌──────────────────────┐      ┌──────────────────────────┐      ┌──────────────────────┐
│ apps/konekto_site_*  │      │   apps/sevvn_api       │      │ apps/konekto_portal  │
│ official site + login│◄────►│ Next.js API-only backend │◄────►│ Next.js hotel portal │
└──────────────────────┘      │ Prisma + Neon/Postgres   │      └──────────────────────┘
                              └────────────┬─────────────┘
                                           │
                                           ▼
                              ┌──────────────────────────┐
                              │ Neon Postgres via Prisma │
                              └────────────┬─────────────┘
                                           │
                                           ▼
                              ┌──────────────────────────┐
                              │ apps/konekto_mobile      │
                              │ Flutter guest app        │
                              │ API mode OR asset mode   │
                              └──────────────────────────┘
```

Key architectural observation:

- The backend is already the strongest and most platform-oriented part of the system.
- The portal is largely wired to real backend endpoints.
- The guest app is in a mixed state: real backend integration exists, but local asset-backed fallback still exists and is the default runtime behavior.
- The platform admin exists but remains a separate Flutter app, with much less test coverage and weaker platform-level controls than the API already suggests.

## 2. Applications

### `apps/sevvn_api`

- Stack: Next.js 16 App Router used as API-only backend
- Language: TypeScript
- Data layer: Prisma 7 + Neon Postgres
- Validation: Zod
- Tests: Vitest
- Role in platform: source of truth for hotel data, staff auth, guest auth, modules catalog, plan presets, services, stays, guests, orders, coupons, support, integrations, analytics, and platform-admin operations

### `apps/sevvn_portal_next`

- Stack: Next.js 16
- Language: TypeScript + React 19
- Data fetching: custom API client + React Query
- Tests: Vitest + Testing Library
- Role in platform: hotel operational portal

### `apps/konekto_mobile`

- Stack: Flutter
- Role in platform: guest app
- Important current behavior: can run either from backend APIs or from packaged asset JSON fixtures, controlled by `USE_API`
- Default behavior today: API-first for pilot-safe builds; asset mode remains only as an explicit fallback

### `apps/sevvn_admin`

- Stack: Flutter
- Role in platform: global Konekto admin / future Sevvn Admin
- Current state: functional cross-tenant admin flows exist, but app is less mature than API and has no automated tests

### `apps/konekto_site`

- Legacy compatibility package kept only for redirects/archive behavior

### `apps/sevvn_site_next`

- Next.js institutional website and official login surface

## 3. Frameworks And Infrastructure

### Backend

- Next.js 16
- Prisma 7
- Neon Postgres
- Zod
- Vitest
- Vercel Blob for uploads
- JWT-based auth

### Frontend

- Portal: Next.js + React 19 + Tailwind 4 + React Query
- Mobile: Flutter
- Admin: Flutter

### Persistence

- Primary database is Postgres through Prisma
- Legacy Firebase references still remain in comments, old assets, lockfiles, and some mobile artifacts
- Product has migrated away from Firestore conceptually, but cleanup is incomplete

## 4. Database And Schema State

Primary schema lives in `apps/sevvn_api/prisma/schema.prisma`.

Core models already present:

- `Hotel`
- `HotelContent`
- `Staff`
- `StaffInvite`
- `Room`
- `Stay`
- `StayNotice`
- `StayMessage`
- `Guest`
- `Order`
- `HotelPaymentAccount`
- `StayPayment`
- `HotelIntegration`
- `Coupon`
- `BrandContent`
- `Service`
- `ServiceItem`
- `Partner`
- `RestaurantTableType`
- `PlatformAdmin`
- `HotelSubscription`
- `PlatformSupportMessage`
- `AnalyticsEvent`

Important conclusion:

- There is already meaningful data modeling for a multi-tenant hospitality product.
- However, several target Sevvn contracts are still implicit or spread across JSON blobs instead of first-class models.
- `Hotel.config` and `HotelContent.data` still carry significant business payload in JSON form.

## 5. Existing API Surface

The backend has a broad API surface already implemented, including:

### Public / guest-facing config

- `GET /api/hotels`
- `GET /api/hotels/:hotelId`
- `GET /api/hotels/:hotelId/content/:docName`
- `GET /api/modules-catalog`
- `GET /api/promotions`

### Guest auth and stay flows

- `POST /api/guest/claim`
- `GET/POST /api/orders`
- `GET/PATCH /api/orders/:orderId`
- `GET/POST /api/guest/messages`
- `POST /api/guest/messages/read`
- `GET /api/guest/messages/unread-count`
- `GET /api/guest/notices`
- `GET /api/guest/orders/unseen-count`
- `POST /api/guest/orders/seen`
- `GET /api/guest/stay-bill`
- `POST /api/guest/stay-bill/pay`

### Hotel portal operations

- staff auth
- hotel config updates
- rooms
- stays
- guests
- orders
- services
- service items
- restaurant table types
- coupons
- integrations
- uploads
- support messages
- dashboard stats
- staff management

### Platform admin

- platform admin login/me
- tenant listing
- tenant creation
- tenant subscription updates
- support inbox

### Integrations

- inbound reservation sync
- inbound menu category sync
- inbound menu item sync
- outbound webhook dispatch on orders
- Pagar.me webhook

Important conclusion:

- The repository is not missing backend breadth.
- The bigger problem is consistency, contract normalization, production-hardening, and end-to-end coherence across portal, mobile, templates, and admin.

## 6. Modules Catalog

Source of truth:

- `apps/sevvn_api/lib/module-catalog.ts`
- `apps/sevvn_api/lib/module-registry.ts`
- `apps/sevvn_api/lib/module-engine.ts`
- `apps/sevvn_api/lib/plan-presets.ts`

Current catalog totals:

- Total modules: 33
- Marked `implemented: true`: 14
- Marked `implemented: false`: 19

Implemented modules in catalog:

- `home`
- `hotel_info`
- `services`
- `bookings`
- `messages`
- `profile`
- `basic_notifications`
- `room_service`
- `restaurant`
- `spa`
- `tours`
- `digital_wallet`
- `promotions`
- `loyalty`

Important caveat:

- `implemented: true` does not mean production-ready.
- In several cases it means there is some combination of backend, screen, or partial flow, but not necessarily a fully platformized module.

## 7. Real Status Of Key Modules

### Core

#### Home

- Exists in all five templates
- Not yet a pure module renderer
- Still hand-authored per template in Flutter
- Status: partial

#### Hotel info / stay info

- Guest claim returns stay and Wi-Fi data
- Separate protected `guestInfo` content exists
- Status: functional for pilot scope

#### Services

- Backend service catalog exists
- Service-module gating exists on backend
- App still supports asset-generated service data
- Status: partial to functional depending on runtime mode

#### Bookings

- There is guest order history, stay bill, and restaurant table reservation behavior inside `Order`
- There is not yet a cleanly separated `Reservation` domain contract in the way the Sevvn target architecture expects
- Status: partial

#### Messages

- Stay-scoped guest/staff messaging exists
- Read tracking exists
- Status: functional

#### Profile

- Exists in app
- Still mixes real and template-specific optional features
- Status: partial

#### Basic notifications

- Notices + unread counters exist
- Status: partial to functional

### Hospitality

#### Room service

- Real backend model
- Real guest order creation
- Real portal operations
- Status: functional

#### Restaurants

- Real backend model
- Real restaurant table reservation behavior
- Real portal operations
- Status: functional

#### Spa

- Can be represented as service/activity
- Backend primitives exist
- Module maturity still depends on hotel configuration and app/API mode
- Status: partial

#### Tours

- Similar to spa
- Status: partial

#### Events

- Present in catalog
- Backend service primitives could support it
- Marked unimplemented in module catalog
- Status: not started as module

#### Concierge

- Present in catalog
- Template demo screens exist
- No module implementation path found
- Status: UI/demo only

#### Laundry, kids club, pools, gym, transport, parking

- Present in catalog only
- Status: not started

### Financial / experience

#### Digital wallet

- Catalog says implemented
- Guest app README explicitly says wallet data is still mock
- Status: UI/partial only

#### Payments

- Stay bill payment exists via Pagar.me
- But `payments` module itself is marked unimplemented in catalog
- Status: domain exists, module layer incomplete

#### Promotions

- Promotions endpoint exists
- Coupon system exists
- Status: partial to functional

#### Loyalty

- Template-specific screens exist only for some templates
- Data is mock
- Status: UI only

#### Reviews, interactive map, digital check-in, digital check-out, smart notifications

- Catalog only
- Status: not started

### Communication

#### Multilingual chat, FAQ, help center

- Catalog only
- Status: not started

## 8. Templates

Current white-label templates:

- Aura
- Bosque
- Elite
- Pulse
- Horizon

Observed real behavior:

- All five templates exist in the guest app
- Only the Home changes visually by template in the real routed app flow
- Other major guest surfaces still use shared UI/theme layers
- Several extra template screens exist but are disconnected demo artifacts

Important conclusion:

- Templates are not yet "visual only" in the strict target architecture.
- They are much closer to presentation-only than before, but the Home layer still carries template-specific structure and behavior assumptions.

## 9. Shared Components / Engines / Platform Concepts Already Present

Already present in code:

- plan presets
- modules catalog
- backend module engine
- mobile module engine
- service-module gating
- guest template registry
- theme resolution
- navigation item resolution for bottom nav

Missing or incomplete relative to target:

- server-delivered resolved module payload rich enough for all surfaces
- formal presentation view-model contract layer
- full backend-driven navigation engine
- backend-driven home layout engine
- template-agnostic module rendering for home

## 10. Authentication State

### Staff auth

- JWT
- server-side role enforcement
- hotel boundary checks in routes
- reasonably mature

### Guest auth

- guest claims with per-guest access code
- token issued after claim
- stay revalidation on every request path via auth guard
- stay expiration enforced reactively

### Platform admin auth

- separate token flow
- full cross-tenant visibility

Important conclusion:

- Auth architecture is directionally sound.
- The strongest issue is not auth existence, but broader security hardening and production controls around it.

## 11. Authorization And Multi-Tenancy

Strengths:

- Many hotel routes derive scope from authenticated staff and compare `staff.hotelId` to route `hotelId`
- Guest routes re-resolve guest against database
- Platform admin is intentionally cross-tenant
- Integration auth hashes API keys

Weaknesses:

- Public `GET /api/hotels/:hotelId` exposes resolved config and module-related state with no auth
- Significant business state still lives in JSON blobs
- Cross-tenant safety depends on disciplined route-by-route checks, not a unified tenant access layer over all query patterns
- There is no evidence of row-level security because tenancy is enforced in application code

## 12. Existing Integrations

Detected integrations:

- Neon Postgres
- Vercel Blob uploads
- Pagar.me payments/webhooks
- inbound hotel system sync APIs
- outbound order webhook dispatch

Integration architecture status:

- better than zero
- not yet abstracted into a full provider model that matches the Sevvn target `IntegrationProvider` contract

## 13. Real Data Vs Mock / Demo Data

### Real data paths

- backend persistence for hotels, rooms, stays, guests, orders, messages, services, coupons, integrations, payments
- portal reads and writes real backend data
- admin reads and writes real backend data

### Mock / demo / fallback paths still present

- guest app asset mode is still the default runtime
- asset-generated services and hotel config remain active
- template-specific demo screens remain in codebase
- loyalty and wallet data remain mock in guest app

Important conclusion:

- The repo already supports real pilot data flows.
- It does not yet guarantee that all runtime paths use them.

## 14. Code Duplication / Legacy / Dead-Weight Signals

Observed duplication or drift risks:

- two institutional site apps
- platform admin in Flutter while portal is in Next.js
- asset repository and HTTP repository maintained in parallel
- comments and docs still refer to older Firebase migration history
- template demo screens coexist with live routed screens

Likely dead-weight / legacy:

- some old template/demo assets and references
- residual Firebase references in mobile project artifacts and package metadata

## 15. Routes Or Features That Are Only Visually Ready

Most important examples:

- loyalty
- wallet
- concierge template screens
- extra template-only onboarding / splash / room-service demo screens
- modules marked implemented in catalog but not yet backed by fully normalized cross-surface contracts

## 16. Technical Risks

1. Guest app still contains an asset fallback path, which can hide regressions if teams validate the wrong build mode.
2. Home/template system is not yet fully driven by platform contracts.
3. JSON-heavy configuration payloads make validation and versioning harder.
4. Platform admin is less tested and less aligned with the newer Next.js portal patterns.
5. Integration architecture is still route-based and tactical, not provider-based and extensible.
6. Security and observability hardening are behind platform breadth.

## 17. Technical Debt

- mixed runtime data sources in mobile
- module implementation status not equal to real readiness
- lack of shared formal contracts package across backend, portal, admin, and app
- Flutter admin with zero tests
- weak separation between temporary template demo assets and real product surfaces
- business state still spread across Prisma models and JSON documents

## 18. Production Blockers

1. Guest app pilot validation must stay on the API-first path and treat asset mode as explicit fallback only.
2. Template validation matrix does not exist yet.
3. Security review and hardening gaps are not closed.
4. Module readiness is not formally documented, so pilot scope can drift into false assumptions.
5. Wallet/loyalty/payment module naming and real readiness are inconsistent.
6. No evidence yet of rate limiting, correlation IDs, or structured observability across the platform.

## 19. External Dependencies

- Neon Postgres
- Vercel Blob
- Pagar.me
- Resend
- potential hotel-side systems using integration endpoints

## 20. Security Gaps

High-level gaps confirmed or strongly suspected:

- no visible rate limiting layer
- no visible correlation ID / structured request logging standard
- public hotel config surface may expose more than ideal
- content documents are JSON blobs with limited schema enforcement
- no clear audit trail model for critical admin mutations

Detailed review is tracked in `docs/security-review.md`.

## 21. Multi-Tenancy Gaps

- tenant isolation is mostly enforced at route level, not by database policy
- some global/public endpoints expose hotel-scoped information without authentication
- mobile fallback mode bypasses true backend tenant enforcement entirely
- `Hotel.config` blobs can accumulate cross-concern data over time

## 22. UX Gaps Across Templates

- only Home is truly template-specific in live routed experience
- some template-specific screens are disconnected demos rather than real app surfaces
- loyalty/wallet support is inconsistent across templates
- no compatibility matrix exists yet to prove the same dataset works in all five templates

## 23. Recommended Pilot Scope Based On Actual Repo

Should be treated as P0 and achievable with focused platform work:

- hotel creation in platform admin
- hotel subscription/preset/template assignment
- hotel branding and module toggles
- room, stay, guest management
- guest claim and session validation
- guest app loading real hotel/stay/module data
- room service ordering
- restaurant reservation/order flows
- stay messaging
- staff order operations
- basic notifications

Should remain partial or disabled during pilot:

- loyalty
- digital wallet
- advanced payments as a module
- events as a first-class module
- smart notifications
- multilingual chat
- digital check-in/check-out
- interactive map

## 24. Bottom Line

This repository is not a blank slate and not just a UI prototype. It already contains a meaningful multi-tenant hospitality platform core, especially in the backend. The main gap is not breadth of features, but consistency and discipline:

- one source of truth everywhere
- no silent fallback to demo data
- real module readiness standards
- template compatibility proven with shared scenarios
- production security and observability

That makes a 30-day pilot plausible only if the work is framed as platform hardening and scope control, not as adding every listed future module.

