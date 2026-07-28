# Canonical Infrastructure Cutover

Last updated: 2026-07-26

## Execution Status

Completed on 2026-07-26:

- canonical GitHub repository created: `blackjeff86/sevvn-platform`
- local `main` branch pushed to the new `sevvn` remote
- institutional site linked to canonical Vercel project `sevvn-site`
- institutional site deployed at `https://sevvn-site.vercel.app`
- API linked to canonical Vercel project `sevvn-api`
- API deployed at `https://sevvn-api.vercel.app`
- hotel portal linked to canonical Vercel project `sevvn-hotel`
- hotel portal deployed at `https://sevvn-hotel.vercel.app`
- admin app linked to canonical Vercel project `sevvn-admin`
- admin app deployed at `https://sevvn-admin.vercel.app`

Still pending in Phase 0:

- decide when to switch the local `origin` remote from the legacy repository
- decide whether the root `konekto-app` Vercel project still needs a canonical `sevvn` counterpart
- replace any remaining hardcoded `konekto-*` production URLs outside temporary fallbacks

## Objective

Promote `Sevvn` to the canonical Git/Vercel identity before the large structural rename in code.

This document translates the rebrand strategy into concrete operational steps.

## Current State Snapshot

### Git

Current remote:

- `origin` → `https://github.com/blackjeff86/konekto-app.git`
- `sevvn` → `https://github.com/blackjeff86/sevvn-platform.git`

Current implication:

- the canonical repository slug still carries the legacy `konekto-app` name

### Vercel root project

Current root `.vercel/project.json`:

- `projectName`: `konekto-app`
- `projectId`: `prj_3f4QSRDwInniXNJ6TwNz5Cgbi8AS`
- `orgId`: `team_fDYb62pkseX8jC8tfimYSmnJ`

### Vercel site project

Current `apps/konekto_site_next/.vercel/project.json`:

- `projectName`: `sevvn-site`
- `projectId`: `prj_l1o0G4JYSCjrJm2ObM4jH7KAkqAU`
- `orgId`: `team_fDYb62pkseX8jC8tfimYSmnJ`

Current live institutional site:

- canonical: `https://sevvn-site.vercel.app`
- legacy fallback: `https://konektositenext.vercel.app`

### Vercel API project

Current `apps/konekto_api/.vercel/project.json`:

- `projectName`: `sevvn-api`
- `projectId`: `prj_KE2Qh4tyRwStRYWjsBVZgBYznVe0`
- `orgId`: `team_fDYb62pkseX8jC8tfimYSmnJ`

Current live API:

- canonical: `https://sevvn-api.vercel.app`

### Vercel hotel portal project

Current `apps/konekto_portal_next/.vercel/project.json`:

- `projectName`: `sevvn-hotel`
- `projectId`: `prj_cjjlIvRzYKF6pKfgi2LIsE1z6ksj`
- `orgId`: `team_fDYb62pkseX8jC8tfimYSmnJ`

Current live hotel portal:

- canonical: `https://sevvn-hotel.vercel.app`

### Vercel admin project

Current `apps/konekto_admin/.vercel/project.json`:

- `projectName`: `sevvn-admin`
- `projectId`: `prj_sAlUbY4VjpJ8NtE2s7RmWrPfDbVy`
- `orgId`: `team_fDYb62pkseX8jC8tfimYSmnJ`

Current live admin:

- canonical: `https://sevvn-admin.vercel.app`

## Why This Phase Comes Before Structural Rename

- avoids renaming folders and packages while the canonical infra still says `konekto`
- prevents future team confusion in remotes, Vercel dashboards, environment variables and deployment ownership
- creates a clean target for the later rename of app directories, package names and imports

## Proposed Canonical Targets

### GitHub

Recommended canonical repository slug:

- `sevvn`

Fallback acceptable slugs if `sevvn` is unavailable:

- `sevvn-platform`
- `sevvn-app`

### Vercel

Recommended project names:

- root platform: `sevvn`
- institutional site: `sevvn-site`
- hotel portal: `sevvn-hotel`
- API: `sevvn-api`
- platform admin: `sevvn-admin`

Note:

- these are operational naming recommendations for Vercel projects
- public domains can still follow a different final convention if desired

## Required Decisions Before Executing The Cutover

1. GitHub repo visibility:
   - private
   - public
2. Final canonical repo slug:
   - `sevvn`
   - or alternate if unavailable
3. Whether old `konekto-*` Vercel projects stay online as fallback during transition
4. Which app gets migrated first after the institutional site:
   - API
   - hotel portal
   - admin
   - root project

## Recommended Execution Order

### Step 1 — Create the canonical GitHub repository

Create the new repo first, without deleting or renaming the old one yet.

Expected result:

- a new canonical remote exists for Sevvn
- the old `konekto-app` repo remains intact as historical/fallback reference

### Step 2 — Push the current codebase to the new repo

Recommended approach:

- keep local worktree exactly as it is
- add the new remote
- push current branch/history
- do not remove the old `origin` until the team confirms the handoff

### Step 3 — Create canonical Vercel projects

Create new Vercel projects under the Sevvn naming convention.

Recommended first project to recreate:

- institutional site (`apps/konekto_site_next`)

Reason:

- lowest operational risk
- already updated in branding and content
- easiest surface to validate publicly

### Step 4 — Link local apps to the new Vercel projects

For each app, refresh its `.vercel/project.json` after linking.

Important:

- do not overwrite current legacy project bindings until the new project is confirmed healthy
- archive old bindings into docs before relinking if needed

### Step 5 — Validate production routing

For each migrated app:

- build succeeds
- production deployment succeeds
- expected environment variables exist
- public URL responds
- smoke-test key route(s)

### Step 6 — Promote Sevvn infra to canonical

Only after validation:

- treat the new repo as primary
- treat the new Vercel projects as primary
- keep the old `konekto` assets only as temporary fallback until the broader migration finishes

## Suggested Command Sequence

The exact commands will depend on repo visibility and final slug, but the sequence should be:

1. create new GitHub repo
2. add new git remote locally
3. push current branch/history
4. create/link new Vercel project for the institutional site
5. deploy and validate
6. repeat for API / portal / admin

## Exit Criteria For Phase 0

- Sevvn has a canonical GitHub repository
- Sevvn has canonical Vercel projects for the active apps
- institutional site is deployed from the new canonical project path
- old `konekto` infra is demoted to fallback only
- Phase 6 structural rename can proceed against the new canonical identity
