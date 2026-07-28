# Rebrand Inventory

Last updated: 2026-07-26

Canonical target brand assumed for this inventory:

- `Sevvn`

Canonical root domain confirmed:

- `sevvn.app`

This inventory does not yet rename folders, package names, or production domains. It maps where the current codebase still depends on:

- `Konekto`
- `konekto`
- `konektto`
- legacy Vercel domains
- legacy package and app identifiers

## Goal

Separate the rebrand into safe execution groups:

1. canonical repo/Vercel infrastructure
2. text and UI branding
3. runtime-critical URLs and legacy site dependency
4. structural identifiers and package names
5. repository/folder reorganization

## 0. Canonical Infrastructure Still Uses Legacy Identity

These references do not break the app by themselves, but they create operational confusion if we keep rebranding code while the source-of-truth infra still says `konekto`.

### Git repository identity

Current state:

- the workspace is still rooted in the legacy repository naming
- any future structural rename done here would still inherit old Git history/remotes unless we promote a new canonical repository

### Vercel project identity

Files:

- [.vercel/project.json](/abs/path/C:/ProjetosFlutter/konekto_app/.vercel/project.json:1)

Current state:

- at least one linked Vercel project still uses legacy `konekto` naming
- runtime migration has already moved login behavior forward, but the deploy/project identity is still old

Recommendation:

- create the new canonical `Sevvn` repository first
- create new `sevvn-*` Vercel projects next
- treat old `konekto` infra as temporary fallback only

## 1. Runtime-Critical Legacy Dependencies

These are the most sensitive references because changing them incorrectly can break login, deploy, or routing.

### Legacy site as active login provider

Files:

- [apps/konekto_site/login.html](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site/login.html:1)
- [apps/konekto_portal_next/lib/siteConfig.ts](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_portal_next/lib/siteConfig.ts:1)

Current state:

- the old static site used to host the real hotel staff login
- the hotel portal used to default to `https://konekto-app.vercel.app/login.html`
- this has now been migrated in code to the Next.js login at `https://konektositenext.vercel.app/login`
- `apps/konekto_site/login.html` should now be treated as a compatibility redirect, not the primary login surface

### Site Next login already exists, but still points to legacy domains

Files:

- [apps/konekto_site_next/app/login/page.tsx](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site_next/app/login/page.tsx:1)
- [apps/konekto_site_next/app/login/LoginForm.tsx](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site_next/app/login/LoginForm.tsx:1)

Current state:

- Next.js login page exists
- it still hardcodes old production API and portal domains
- this is the most likely migration target for retiring the legacy static site

### Admin still points to legacy institutional site domain

Files:

- [apps/konekto_admin/lib/site_config.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_admin/lib/site_config.dart:1)

Current state:

- defaults to `https://konektositenext.vercel.app`

## 2. User-Facing Brand Text

These are safer to change first because they affect presentation more than wiring.

### Root docs and repo description

Files:

- [README.md](/abs/path/C:/ProjetosFlutter/konekto_app/README.md:1)
- [apps/konekto_api/README.md](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/README.md:1)
- [apps/konekto_admin/README.md](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_admin/README.md:1)
- [apps/konekto_mobile/README.md](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/README.md:1)
- [apps/konekto_portal_next/README.md](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_portal_next/README.md:1)

### Site copy and contact channels

Files:

- [apps/konekto_site/index.html](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site/index.html:1)
- [apps/konekto_site/login.html](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site/login.html:1)
- [apps/konekto_site_next/app/login/page.tsx](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site_next/app/login/page.tsx:1)
- [apps/konekto_site_next/content/plans.ts](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site_next/content/plans.ts:1)

Current state:

- several pages already say `Sevvn`
- but support and contact e-mails still use `@konekto.app`
- some links still point to old production projects
- the internal admin UI is partially rebranded, but structural symbols still keep `Konekto*` names

### Admin and app window titles / manifest names

Files:

- [apps/konekto_admin/web/index.html](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_admin/web/index.html:1)
- [apps/konekto_admin/web/manifest.json](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_admin/web/manifest.json:1)
- [apps/konekto_mobile/android/app/src/main/AndroidManifest.xml](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/android/app/src/main/AndroidManifest.xml:1)
- [apps/konekto_mobile/windows/runner/Runner.rc](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/windows/runner/Runner.rc:1)
- [apps/konekto_mobile/windows/runner/main.cpp](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/windows/runner/main.cpp:1)

## 3. Structural Identifiers Still Named Konekto

These are not just copy changes. They affect imports, build outputs, package resolution, and possibly mobile bundle identifiers.

### App folder names

Current folders:

- `apps/konekto_admin`
- `apps/konekto_api`
- `apps/konekto_mobile`
- `apps/konekto_portal_next`
- `apps/konekto_site`
- `apps/konekto_site_next`

Impact of renaming:

- scripts
- documentation
- Vercel root directories
- references across repo

### Flutter package name in guest app

Files:

- [apps/konekto_mobile/pubspec.yaml](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/pubspec.yaml:1)

Current state:

- package name is `konekto`
- imports across Flutter code use `package:konekto/...`

Impact:

- very large refactor
- must be coordinated with all mobile imports and tests

### Flutter admin package name

Files:

- [apps/konekto_admin/pubspec.yaml](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_admin/pubspec.yaml:1)

Current state:

- package name is `konekto_admin`

### Node package names

Files:

- [apps/konekto_api/package.json](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/package.json:1)
- [apps/konekto_portal_next/package.json](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_portal_next/package.json:1)
- [apps/konekto_site/package.json](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site/package.json:1)
- [apps/konekto_site_next/package.json](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_site_next/package.json:1)

### Mobile platform identifiers

Files:

- [apps/konekto_mobile/android/app/build.gradle.kts](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/android/app/build.gradle.kts:1)
- [apps/konekto_mobile/android/app/src/main/kotlin/com/example/konekto/MainActivity.kt](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/android/app/src/main/kotlin/com/example/konekto/MainActivity.kt:1)
- [apps/konekto_mobile/windows/CMakeLists.txt](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/windows/CMakeLists.txt:1)
- [apps/konekto_mobile/windows/runner/Runner.rc](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/windows/runner/Runner.rc:1)

Impact:

- Android application id
- native package namespace
- Windows executable/product name

## 4. Internal Code Symbols And Classes

Examples:

- `KonektoBrand`
- `KonektoMark`
- `HomeKonektoPage`
- storage keys like `konekto_admin_auth_token`
- webhook headers like `X-Konekto-Signature`

These are scattered across Flutter and React code. Renaming them is safe only after the brand/text phase is stable, because:

- they are used in many imports
- some names are also file names
- some names are shared with assets and tests

## 5. Legacy / Historical References That Should Not Be Blindly Replaced

These should be reviewed, not mass-replaced:

- migration history comments
- archived legacy templates
- old task/spec documents
- test fixtures intentionally referencing old values

Examples:

- `legacy-templates/`
- `tasks/`
- `specs/`
- comments describing historical migration from older Konekto states

## 6. Recommended Execution Order

### Phase A — safe surface rebrand

- update visible UI text to `Sevvn`
- update docs/README copy
- update titles, labels, manifest display names
- keep folder names and package names unchanged

### Phase B — canonical infrastructure cutover

- create the new canonical `Sevvn` repository
- create the new Vercel projects under `sevvn-*`
- validate deploy and routing in the new environment
- keep the old `konekto` infra alive until the new path is stable

### Phase C — remove legacy site from runtime path

- move real login flow fully to `apps/konekto_site_next`
- switch portal/admin defaults away from `konekto-app.vercel.app`
- confirm production routing works
- only then archive or remove `apps/konekto_site`

### Phase D — structural rename

- rename app folders
- rename package names
- rename Flutter import root from `package:konekto/...`
- rename admin package ids and Node package names

### Phase E — native/mobile cleanup

- Android package ids
- Windows binary naming
- leftover Firebase project ids and old identifiers

## 7. Decisions Still Needed Before Runtime Changes

These values are not safe to invent:

1. canonical public brand spelling if different from `Sevvn`
2. new production subdomains for:
   - login site
   - portal
   - API
   - admin
3. new contact/support e-mails
4. whether app folder names should become `sevvn_*` or a different naming convention

## 8. Immediate Recommendation

Start with:

- Phase B canonical repo/Vercel cutover
- Phase A safe visible text rebrand in parallel where low-risk

Do not yet:

- rename Flutter package imports
- rename mobile application ids
- delete `apps/konekto_site`
- change production domains without explicit target values
