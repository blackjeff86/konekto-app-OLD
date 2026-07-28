# Konekto Hotel Live Rehearsal Prep

Last updated: 2026-07-27

## Objective

Prepare the live pilot rehearsal around the canonical tenant chosen by product:

- canonical rehearsal tenant: `Konekto Hotel`

This document turns that decision into an execution-ready checklist for the real environment.

## Canonical Tenant Decision

As of 2026-07-27, the representative tenant for the Sevvn live rehearsal is:

- tenant name: `Konekto Hotel`

This replaces the previous open question about which hotel should be used for the canonical pilot run.

## Repository Clues About This Tenant

Based on repository history already captured in project docs:

- `Konekto Hotel` used to be confused with legacy `hotel_1`
- it was later corrected into a real client tenant with a real UUID
- the documented real tenant id is:
  - `b370eef7-0317-4f03-9bdb-c5bfe1b17682`
- its selected template was documented as:
  - `bosque`

Evidence already present in repo history:

- `tasks/todo-guest-app-whitelabel.md`

Important caution:

- the old asset files under `apps/konekto_mobile/assets/tenant_assets/hotels/hotel_1/` are historical fallback/demo material only
- they are not proof of the real current backend state of `Konekto Hotel`

## Rehearsal Baseline For This Tenant

Use `Konekto Hotel` as the operational baseline.

Default recommendation for the live run:

- preserve the tenant as currently configured instead of resetting it just to match a generic script
- assume `bosque` stays as the visual baseline unless the live environment shows a reason to switch temporarily

Pilot-safe module target for this tenant:

- `hotel_info`
- `messages`
- `room_service`
- `restaurant`
- `services`
- `bookings`
- `profile`
- `basic_notifications`

Controlled optional modules:

- `spa`
- `tours`
- `promotions`

Explicitly outside pass/fail scope:

- `wallet`
- `loyalty`
- `concierge`
- `events`
- `digital_checkin`
- `digital_checkout`

## Live Rehearsal Checklist

### 1. Confirm tenant identity in Sevvn Admin

Verify in the real environment:

- hotel name is `Konekto Hotel`
- tenant id matches the real client record being used for rehearsal
- subscription/preset is visible and editable

Minimum desired state:

- preset: `premium`
- status: usable for rehearsal (`trial` or `active`)

### 2. Confirm template and module state

Verify in portal/admin:

- active template is visible
- allowed templates are resolved correctly
- pilot-safe modules are enabled
- unsupported modules are not being treated as live proof

Current expected baseline from repo history:

- template likely `bosque`

### 3. Confirm operational room state

Verify:

- at least one room exists or can be created safely
- room `101` is the preferred canonical rehearsal room

### 4. Open one active stay

Verify:

- a stay can be opened for room `101`
- dates are valid and not already expired

### 5. Create one guest

Preferred guest for canonical evidence:

- `Ana Silva`

Verify:

- guest is attached to the new active stay
- an access code is generated

### 6. Claim in the guest app

Run the guest app in:

- `APP_RUNTIME_MODE=api`

Verify:

- claim succeeds with the generated access code
- the app resolves hotel/stay information from the backend
- Wi-Fi and room data are returned correctly

### 7. Validate pilot-safe guest flows

Minimum pass scope:

- home loads
- hotel info/Wi-Fi is visible
- room service works on real data
- restaurant flow works on real data
- messages/notices/basic counters work

### 8. Record pass/fail evidence

Capture a short evidence note with:

- date of run
- tenant used: `Konekto Hotel`
- template used
- room used
- guest used
- whether claim succeeded in API mode
- which flows passed
- any blockers or regressions found

## Known Constraint Right Now

This repository session does not prove the live backend state by itself.

What we have now:

- strong repository evidence of the flow
- historical documentation tying `Konekto Hotel` to the real tenant migration

What still requires environment execution:

- the actual live admin/portal/app run
- the final pass/fail evidence

## Recommended Immediate Next Action

When execution time comes, start with:

1. find `Konekto Hotel` in Sevvn Admin
2. confirm its preset and template
3. prepare room `101`
4. create one fresh stay and one guest
5. claim in API mode

That is the smallest real rehearsal that can close the remaining pilot gap.
