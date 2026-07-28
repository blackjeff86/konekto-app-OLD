# Rebrand Plan

Last updated: 2026-07-26

## Objective

Rebrand the repository and runtime surfaces from `Konekto` / `konektto` to `Sevvn`, while safely retiring the legacy static site and avoiding accidental breakage in login, deploy, package resolution, or mobile builds.

Confirmed root domain:

- `sevvn.app`

## Constraints

- The guest Flutter app still uses `package:konekto/...` imports.
- Production portal/API/admin subdomains for Sevvn are not yet fully defined in the repo.
- Some compatibility-sensitive identifiers still carry the old brand:
  `konekto_admin_auth_token`, `X-Konekto-Signature`, app folder names, package names.
- The current Git repository slug and some Vercel projects still carry the legacy `konekto` identity.

## Phase 0 — Canonical Infrastructure Cutover

Goal:

- establish `Sevvn` as the canonical operational identity before the high-risk code rename

Status:

- completed on 2026-07-26 for the active applications

Scope:

- create the new canonical Git repository with the correct project name
- create new Vercel projects with `sevvn-*` naming
- connect the active codebase to the new repo/projects without deleting the legacy ones yet
- validate that the active apps can deploy in the new environment

Operational docs:

- [canonical-infra-cutover.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/canonical-infra-cutover.md)
- [vercel-project-migration-map.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/vercel-project-migration-map.md)

Why this comes first:

- avoids doing a deep code rebrand while Git/Vercel still present the product as `konekto`
- reduces long-term operational confusion in remotes, deploy dashboards, environment variables, and team onboarding
- creates a clean target for the later structural rename

Acceptance criteria:

- a new canonical repository exists for the Sevvn codebase
- the main Vercel projects also exist under the Sevvn naming convention
- legacy `konekto` repo/projects remain available only as fallback during migration
- Phase 6 can target the new canonical repo/projects instead of the old ones

## Phase 1 — Inventory And Safety Rails

Status: completed

Deliverables:

- [rebrand-inventory.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/rebrand-inventory.md)
- explicit separation between safe text changes and risky structural changes

## Phase 2 — Surface Rebrand

Goal:

- change visible brand text to `Sevvn`
- keep runtime/package structure stable

Scope:

- root README and app READMEs
- visible page titles
- manifest display names
- user-facing labels like `Konekto` or `konektto`
- comments can be updated selectively where they describe the current product, not the migration history

Should not include yet:

- folder renames
- Flutter package root renames
- Android application id changes
- repository slug or Vercel project changes

Acceptance criteria:

- visible UI text no longer says `Konekto` or `konektto` except in historical references
- no import path changes required
- no runtime URL changes required

## Phase 3 — Login Migration Off Legacy Site

Goal:

- stop depending on `apps/konekto_site/login.html`

Status:

- completed in code

Scope:

- make `apps/konekto_site_next/app/login` the primary login implementation
- move any remaining runtime logic from legacy HTML to Next.js login
- update portal/admin defaults to new login endpoint

Dependencies:

- target production login subdomain/path
- target production API/portal subdomains

Acceptance criteria:

- portal login flow works without `apps/konekto_site`
- admin links to the correct institutional site
- no hardcoded legacy `konekto-*` production domains remain in active login code

## Phase 4 — Visible Admin + Runtime Branding

Goal:

- finish the safe operator-facing rebrand in active surfaces

Status:

- completed on 2026-07-27

Operational doc:

- [visible-runtime-branding-cleanup-2026-07-27.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/visible-runtime-branding-cleanup-2026-07-27.md)

Scope:

- internal admin labels and login hints
- default sender/display names used by operational flows
- current-product comments where they still describe Sevvn as `Konekto`

Acceptance criteria:

- active admin UI no longer shows `Konekto` in primary visible labels
- default operational branding uses `Sevvn`
- no structural rename is required for this phase

## Phase 5 — Legacy Site Retirement

Goal:

- archive or remove `apps/konekto_site`

Status:

- runtime retirement completed on 2026-07-27

Operational doc:

- [legacy-site-retirement-2026-07-27.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/legacy-site-retirement-2026-07-27.md)

Acceptance criteria:

- no active app points to `apps/konekto_site`
- no production login path depends on `login.html` there
- static legacy assets needed by other apps are copied or relocated first

## Phase 6 — Structural Rename

Goal:

- rename repository-level identifiers to match `Sevvn`

Scope candidates:

- `apps/konekto_api` -> `apps/sevvn_api`
- `apps/konekto_mobile` -> `apps/sevvn_mobile`
- `apps/konekto_admin` -> `apps/sevvn_admin`
- `apps/konekto_portal_next` -> `apps/sevvn_portal_next`
- `apps/konekto_site_next` -> `apps/sevvn_site_next`

Also includes:

- package names in `package.json`
- Flutter package names in `pubspec.yaml`
- import roots like `package:konekto/...`

Risk:

- highest-risk phase of the rebrand
- requires broad refactor and full build validation

Acceptance criteria:

- code compiles after path/package rename
- Vercel root configuration is updated
- no unresolved import paths remain

## Phase 7 — Native Platform Renames

Goal:

- rename mobile/native identifiers

Scope:

- Android application id / namespace
- Windows executable metadata
- any residual native app labels

Acceptance criteria:

- mobile builds still succeed
- app display names reflect `Sevvn`

## Open Decisions

Still required from product/operations side:

1. final production subdomains under `sevvn.app`
2. final support and contact e-mails
3. whether `Sevvn` should be used everywhere, or if any surface uses `SEVVN`
4. preferred folder naming convention after rebrand
5. whether the old `konekto` GitHub/Vercel assets will be archived or kept indefinitely as fallback

## Next Recommended Execution Step

Proceed with the remaining safe rebrand and platform hardening work:

- finish Phase 4 visible admin and runtime branding
- retire `apps/konekto_site` from the active runtime path
- continue with platform hardening and pilot-readiness work before structural renames

Then continue with:

- safe visible rebrand text
- keep structure stable
- postpone folder/package/native renames until exact production targets and pilot scope are stable
