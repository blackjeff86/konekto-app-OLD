# Implementation Plan: Aura Guest Template Migration To TypeScript

## Overview

This plan migrates the Aura guest template from the legacy Flutter/web prototype assets in `apps/konekto_mobile/templates/Aura template/` into `apps/sevvn_guest_next`, turning the guest app into a thin TypeScript shell over the Sevvn platform APIs and module engine.

The goal is not to rebuild static screens 1:1 first and wire them later. Each slice must already consume real backend data from one authenticated hotel/guest context, with the Aura template acting only as presentation. The first commercial target is the Essential package, so the initial implementation should prioritize the modules and surfaces that are truly available there.

## Architecture Decisions

- `apps/sevvn_guest_next` remains the canonical TypeScript guest app target.
- Aura becomes a template definition composed of:
  - visual tokens;
  - layout primitives;
  - surface-specific component variants.
- Business data comes only from the backend contracts already exposed by `apps/sevvn_api`.
- The guest app must remain hotel-scoped through the authenticated guest claim token. No free hotel switcher or URL-selected tenant state is allowed.
- The Essential package is the first migration target, so Aura should first support the surfaces that can be backed by:
  - hotel identity / room / Wi-Fi;
  - enabled modules;
  - services directory;
  - room service / minibar capable services;
  - concierge/messages;
  - basic notifications;
  - profile / stay context.
- Screens that are visually present in Aura but not yet fully backed by a mature module should be implemented as module-aware placeholders, not fake hardcoded product behavior.
- We will migrate by vertical slices:
  - template shell and theme;
  - Aura home;
  - Aura services directory;
  - Aura service detail / room service;
  - Aura communications surfaces;
  - Aura profile and secondary surfaces.

## Source Mapping

Aura source screens identified in `apps/konekto_mobile/templates/Aura template/`:

- `aura_splash_screen`
- `aura_onboarding`
- `aura_home`
- `aura_services_directory`
- `aura_room_service`
- `aura_concierge_chat`
- `aura_notifications`
- `aura_profile`

Current `apps/sevvn_guest_next` status:

- already authenticates guest by access code;
- already loads hotel config, services, modules catalog, orders, and messages;
- already enforces tenant-safe hotel scoping;
- still uses a generic shell/UI instead of an Aura-specific layout system.

## Dependency Graph

Template tokens and shell
    |
    +-- Aura home composition
    |
    +-- Aura services directory
    |      |
    |      +-- Aura service detail / room service
    |
    +-- Aura communications surfaces
    |
    +-- Aura profile / secondary surfaces

## Task List

### Phase 1: Foundation And Aura Shell

## Task 1: Define Aura theme tokens and shared shell primitives

**Description:** Extract Aura visual language from the legacy template HTML and create a reusable TypeScript theme layer in `apps/sevvn_guest_next`, including colors, typography intent, spacing, cards, top bar, and bottom navigation behavior.

**Acceptance criteria:**
- [ ] Aura tokens exist as code, not copied inline per screen.
- [ ] Shared Aura primitives can render top bar, section headers, cards, and bottom nav.
- [ ] Tokens accept backend-driven hotel palette overrides without breaking the base Aura identity.

**Verification:**
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: guest shell renders Aura primitives consistently

**Dependencies:** None

**Files likely touched:**
- `apps/sevvn_guest_next/lib/theme/*`
- `apps/sevvn_guest_next/app/globals.css`
- `apps/sevvn_guest_next/app/guest-root.tsx`

**Estimated scope:** Medium

## Task 2: Restructure the guest shell around view routes/surfaces instead of one generic monolith

**Description:** Refactor the current `GuestRoot` so Aura surfaces can be composed cleanly by concern instead of continuing to grow as one large file.

**Acceptance criteria:**
- [ ] Home, services, service detail, messages/concierge, notifications, and profile are split into dedicated components.
- [ ] Bottom navigation remains module-aware.
- [ ] Guest session and hotel context stay centralized.

**Verification:**
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: navigation still works after the split

**Dependencies:** Task 1

**Files likely touched:**
- `apps/sevvn_guest_next/app/guest-root.tsx`
- `apps/sevvn_guest_next/components/guest/*`

**Estimated scope:** Medium

### Checkpoint: Shell

- [ ] Aura theme primitives exist
- [ ] Guest shell is split into maintainable surfaces
- [ ] No regression in claim/session flow

### Phase 2: Essential Aura Core

## Task 3: Port Aura home as a real Essential-backed surface

**Description:** Replace the generic home with an Aura home that reads room, Wi-Fi, stay dates, promotions/highlights, and enabled quick actions from the real authenticated guest context and hotel config.

**Acceptance criteria:**
- [ ] Header, summary card, stay cards, and quick actions follow the Aura visual language.
- [ ] Home content reads real hotel and guest data, not placeholders.
- [ ] Quick actions only surface modules actually enabled for that hotel.

**Verification:**
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: real pilot guest session shows hotel-scoped home data

**Dependencies:** Task 2

**Files likely touched:**
- `apps/sevvn_guest_next/components/guest/aura/AuraHome.tsx`
- `apps/sevvn_guest_next/lib/module-engine.ts`

**Estimated scope:** Medium

## Task 4: Port Aura services directory as a module-driven catalog surface

**Description:** Implement the Aura services directory using live services returned by the backend, grouped and rendered according to module/service metadata instead of a static bento grid.

**Acceptance criteria:**
- [ ] Services list uses live API data.
- [ ] Service imagery, grouping, and CTA entry points are data-driven.
- [ ] Empty states are graceful when a hotel has fewer enabled services.

**Verification:**
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: real services appear in Aura layout

**Dependencies:** Task 2

**Files likely touched:**
- `apps/sevvn_guest_next/components/guest/aura/AuraServicesDirectory.tsx`
- `apps/sevvn_guest_next/lib/api/hotels.ts`

**Estimated scope:** Medium

## Task 5: Port Aura room service/detail flow using live service items

**Description:** Convert the Aura room-service visual into a reusable service detail surface that works for room service and other item-driven Essential services.

**Acceptance criteria:**
- [ ] Service detail reads real items, images, pricing, and scheduling availability.
- [ ] Order creation uses the existing backend endpoints.
- [ ] Minibar-capable items respect backend configuration rather than template-only assumptions.

**Verification:**
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: create at least one real guest order in the Aura flow

**Dependencies:** Task 4

**Files likely touched:**
- `apps/sevvn_guest_next/components/guest/aura/AuraServiceDetail.tsx`
- `apps/sevvn_guest_next/lib/api/orders.ts`

**Estimated scope:** Medium

### Checkpoint: Essential Core

- [ ] Claim -> Aura Home -> Aura Services -> Aura Service Detail works end to end
- [ ] Guest app is still just a shell over platform modules
- [ ] Essential-backed flow is usable for the pilot hotel

### Phase 3: Communications And Secondary Surfaces

## Task 6: Port Aura concierge/messages surface using the real communication module

**Description:** Rebuild the Aura concierge chat screen on top of the existing guest/staff message contracts so it behaves like a module consumer, not a bespoke local chat.

**Acceptance criteria:**
- [ ] Message list and send flow use the live guest messaging endpoints.
- [ ] Aura concierge presentation reads module configuration where available.
- [ ] Empty and loading states are consistent with the rest of the shell.

**Verification:**
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: send and read a live message in the Aura flow

**Dependencies:** Task 2

**Files likely touched:**
- `apps/sevvn_guest_next/components/guest/aura/AuraConcierge.tsx`
- `apps/sevvn_guest_next/lib/api/messages.ts`

**Estimated scope:** Medium

## Task 7: Port Aura notifications as a consumer of `basic_notifications`

**Description:** Implement the Aura notifications screen as the presentation layer for the current notifications/notices capabilities, making explicit what is already real and what is still “coming soon”.

**Acceptance criteria:**
- [ ] Notifications screen reads live notification/notices data where available.
- [ ] Unsupported richer interactions are labeled as in progress instead of faked.
- [ ] Bottom-nav/state transitions remain coherent with the Aura shell.

**Verification:**
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: unread/notification content is visible in Aura

**Dependencies:** Task 2

**Files likely touched:**
- `apps/sevvn_guest_next/components/guest/aura/AuraNotifications.tsx`
- `apps/sevvn_guest_next/lib/api/*`

**Estimated scope:** Medium

## Task 8: Port Aura profile / stay context surface

**Description:** Rebuild the Aura profile screen to show guest identity, stay details, and hotel context from the authenticated session and guest claim data.

**Acceptance criteria:**
- [ ] Profile reflects the authenticated guest and stay context.
- [ ] No fake editable profile fields are introduced without backend support.
- [ ] The surface is visually aligned with the Aura references.

**Verification:**
- [ ] Build succeeds: `npm run build`
- [ ] Manual check: authenticated guest data appears correctly

**Dependencies:** Task 2

**Files likely touched:**
- `apps/sevvn_guest_next/components/guest/aura/AuraProfile.tsx`

**Estimated scope:** Small

### Checkpoint: Aura Coverage

- [ ] Aura home, services, room service, concierge, notifications, and profile exist in TypeScript
- [ ] All migrated Aura screens read live Sevvn data/contracts
- [ ] No migrated Aura surface depends on Flutter-only runtime behavior

### Phase 4: Replacement Readiness

## Task 9: Define what stays placeholder vs what is production-ready for Essential

**Description:** Review all Aura surfaces and mark which ones are fully live for Essential, which are module-gated but hidden, and which are visible as “em breve” only because the backend capability is not yet complete.

**Acceptance criteria:**
- [ ] Each Aura surface has a clear runtime status.
- [ ] We do not expose fake interactions as finished product.
- [ ] The pilot path is documented for manual validation.

**Verification:**
- [ ] Manual review against enabled modules for the pilot hotel
- [ ] Final build succeeds: `npm run build`

**Dependencies:** Tasks 3-8

**Files likely touched:**
- `apps/sevvn_guest_next/components/guest/*`
- `tasks/todo.md`

**Estimated scope:** Small

## Risks And Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Aura HTML is richer than current backend-backed capability for some screens | High | Implement honest placeholder states instead of fake product behavior |
| `GuestRoot` monolith becomes unmaintainable during migration | High | Split shell before porting more screens |
| Essential scope gets polluted by Premium/Enterprise expectations | Medium | Gate every surface by real enabled modules and package availability |
| Palette/theme port becomes inconsistent across screens | Medium | Build shared Aura primitives first |

## Open Questions

- Should Aura onboarding/splash remain part of the first production path, or do we keep claim-first access as the initial entry flow and only later style the pre-auth sequence?
- Should the first Essential cut expose a wallet/reservations tab in Aura, or keep those hidden until the underlying flows are fully aligned?
