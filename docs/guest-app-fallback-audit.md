# Guest App Fallback Audit

Last updated: 2026-07-26

## Objective

Map the remaining fallback, demo, and mock paths in `apps/konekto_mobile` after the mobile app was moved to API-first runtime by default.

This document separates:

- active runtime fallbacks that still affect pilot confidence
- dormant demo surfaces that do not currently affect the live guest journey
- residual bundled assets that remain in the repo but are no longer part of the official pilot truth path

## Executive Summary

The most dangerous fallback was the old default runtime path itself. That is now fixed:

- `APP_RUNTIME_MODE=api` is the default path
- `API_BASE_URL` now defaults to `https://sevvn-api.vercel.app`
- asset mode remains available only when explicitly requested

Even after that change, the guest app still contains three important categories of fallback behavior:

1. explicit asset-mode repositories that can still bypass backend truth
2. runtime-safe fallbacks that prevent crashes but can hide incomplete configuration
3. template/demo surfaces that still use mock data and are not connected to the live guest journey

## 1. Active Runtime Fallbacks That Still Matter

### 1.1 Explicit asset mode still exists

Files:

- [apps/konekto_mobile/lib/data/tenant_repository_provider.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/data/tenant_repository_provider.dart:1)
- [apps/konekto_mobile/lib/data/asset_tenant_repository.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/data/asset_tenant_repository.dart:1)

Current behavior:

- `APP_RUNTIME_MODE=asset` still replaces the backend with bundled JSON fixtures
- `USE_API=false` still acts as a legacy alias to asset mode

Pilot impact:

- safe as an explicit dev/demo fallback
- unsafe if anyone treats it as evidence that the pilot path is healthy

Decision:

- keep for controlled development only
- never use as pilot validation evidence

### 1.2 Promotions can still come from bundled JSON in asset mode

Files:

- [apps/konekto_mobile/lib/data/asset_tenant_repository.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/data/asset_tenant_repository.dart:243)
- [apps/konekto_mobile/assets/data/promotions.json](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/assets/data/promotions.json:1)

Current behavior:

- in asset mode, pre-login promotions come from local JSON/images
- in API mode, promotions come from `GET /api/promotions`

Pilot impact:

- no problem in API mode
- can still mislead internal demos if the wrong mode is used

### 1.3 Module navigation still has a fixed fallback

Files:

- [apps/konekto_mobile/lib/app/tenants/tenant_home_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/tenant_home_page.dart:52)
- [apps/konekto_mobile/lib/theme/guest_app_theme.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/theme/guest_app_theme.dart:77)

Current behavior:

- bottom navigation starts from `kGuestNavItems`
- if module catalog resolution fails, the app keeps the fixed navigation instead of breaking

Pilot impact:

- good crash-resistance
- still a truth-risk because a catalog/config problem may degrade into a generic usable UI instead of loudly exposing the mismatch

Decision:

- acceptable for now
- should be documented as resilience fallback, not platform truth

### 1.4 Template selection still falls back to `aura`

Files:

- [apps/konekto_mobile/lib/app/tenants/tenant_home_page.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/app/tenants/tenant_home_page.dart:144)
- [apps/konekto_mobile/lib/templates/guest_template_registry.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/templates/guest_template_registry.dart:18)

Current behavior:

- missing or unknown `tenantConfig['template']` falls back to `GuestTemplateId.aura`

Pilot impact:

- avoids app failure for malformed tenant data
- can hide missing template assignment in hotel setup

Decision:

- acceptable during hardening
- should be paired with admin/setup validation so hotels do not silently drift to Aura

### 1.5 Shared guest theme still falls back to legacy fixed tokens

Files:

- [apps/konekto_mobile/lib/theme/guest_app_theme.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/theme/guest_app_theme.dart:4)

Current behavior:

- non-home guest surfaces use a fixed shared token set derived from the old visual baseline

Pilot impact:

- not a backend truth problem
- still a product-coherence fallback because template choice does not fully control the whole guest experience

Decision:

- acceptable for pilot
- should be revisited later as part of template-system convergence, not as a blocker for this month

## 2. Demo Or Mock Surfaces Not On The Active Guest Journey

These do not currently block the pilot path, but they inflate perceived readiness if discussed loosely.

### 2.1 Template-specific extra screens remain demo-only

Files:

- [apps/konekto_mobile/lib/templates/README.md](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/templates/README.md:1)
- `lib/templates/<template>/splash_screen.dart`
- `lib/templates/<template>/onboarding_screen.dart`
- `lib/templates/<template>/room_service_screen.dart`
- `lib/templates/<template>/concierge_chat_screen.dart`
- `lib/templates/<template>/services_directory_screen.dart`

Current behavior:

- only Home is wired into the active guest journey
- the extra template screens still use demonstration data and are not route-connected to the live runtime

Pilot impact:

- no direct runtime risk
- real product readiness can be overstated if these are mistaken for active features

### 2.2 Loyalty and wallet remain mock/template-bound

Files:

- [apps/konekto_mobile/lib/modules/screens/loyalty_wallet_dispatch.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/modules/screens/loyalty_wallet_dispatch.dart:1)
- `lib/modules/screens/loyalty/*.dart`
- `lib/modules/screens/wallet/*.dart`

Current behavior:

- only some templates have these screens
- values are still mock/demo data

Pilot impact:

- should remain outside the pilot truth path
- must not be presented as production-ready capabilities

### 2.3 Concierge and services-directory mock content still exists

Files:

- `lib/templates/shared/guest_template_service_category.dart`
- `lib/templates/shared/guest_template_menu_item.dart`
- `lib/templates/shared/widgets/guest_template_chat_bubble.dart`

Current behavior:

- visual support components remain geared to mockups, not to real backend content

Pilot impact:

- documentation/truth risk, not a live-flow blocker

## 3. Residual Bundled Assets Still Present In The Repo

### 3.1 Full tenant JSON bundles remain in source control

Files:

- `apps/konekto_mobile/assets/tenant_assets/hotels/hotel_1/*`
- `apps/konekto_mobile/assets/tenant_assets/hotels/hotel_2/*`

Current behavior:

- these assets are still needed for explicit asset-mode fallback

Pilot impact:

- acceptable while asset mode still exists
- should be treated as non-production fixtures

### 3.2 Legacy map data still exists as bundled asset residue

Files:

- `apps/konekto_mobile/assets/tenant_assets/hotels/*/mapa_data.json`

Current behavior:

- interactive map is not part of the active app journey
- map assets still remain from older flows

Pilot impact:

- no current runtime impact
- repo cleanup candidate later

## 4. Recommended Handling By Category

### Keep for now, but explicitly non-pilot

- asset mode runtime
- bundled tenant fixtures
- bundled promotions fixtures

### Keep for now as resilience fallback, but monitor

- fixed nav fallback when module catalog resolution fails
- fallback to `aura` when template is missing

### Keep, but mark clearly as non-ready product surfaces

- loyalty screens
- wallet screens
- concierge/demo template screens
- extra template mock screens beyond Home

### Candidate cleanup after pilot hardening

- map fixture residue
- old mock template support components that never connect to real data

## 5. Concrete Outcome For The 30-Day Plan

Task 2 conclusion:

- the highest-risk hidden fallback is already addressed by making API mode the default
- remaining fallbacks are now understood and classified
- the next step is not deleting everything blindly; it is freezing the official pilot module scope and marking mock/demo surfaces accordingly

Recommended next task:

- proceed to Task 3 and lock the pilot scope in docs/configs around the modules that are truly in play
