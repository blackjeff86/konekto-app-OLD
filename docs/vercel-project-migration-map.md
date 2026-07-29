# Vercel Project Migration Map

Last updated: 2026-07-26

## Current Linked Projects

| Scope | Local path | Current Vercel project | Current project ID | Current status |
|---|---|---|---|---|
| Root | `.` | `konekto-app` | `prj_3f4QSRDwInniXNJ6TwNz5Cgbi8AS` | legacy identity |
| Institutional site | `apps/sevvn_site_next` | `sevvn-site` | `prj_l1o0G4JYSCjrJm2ObM4jH7KAkqAU` | canonical and live |
| API | `apps/sevvn_api` | `sevvn-api` | `prj_KE2Qh4tyRwStRYWjsBVZgBYznVe0` | canonical and live |
| Hotel portal | `apps/sevvn_portal_next` | `sevvn-hotel` | `prj_cjjlIvRzYKF6pKfgi2LIsE1z6ksj` | canonical and live |
| Admin | `apps/sevvn_admin` | `sevvn-admin` | `prj_sAlUbY4VjpJ8NtE2s7RmWrPfDbVy` | canonical and live |

## Recommended Target Mapping

| Local path | Recommended new Vercel project | Migration priority | Notes |
|---|---|---|---|
| `apps/sevvn_site_next` | `sevvn-site` | P0 | easiest first migration |
| `apps/sevvn_api` | `sevvn-api` | P1 | runtime-critical |
| `apps/sevvn_portal_next` | `sevvn-hotel` | P1 | coupled to login + API |
| `apps/sevvn_admin` | `sevvn-admin` | P2 | internal surface |
| `.` | `sevvn` | P2 | use only if root deployment still matters operationally |

## Suggested Cutover Sequence

1. `apps/sevvn_site_next` - completed on 2026-07-26
2. `apps/sevvn_api` - completed on 2026-07-26
3. `apps/sevvn_portal_next` - completed on 2026-07-26
4. `apps/sevvn_admin` - completed on 2026-07-26
5. root project if still needed - pending

## Validation Checklist Per Project

- project created with Sevvn naming
- local directory linked to the new project
- build passes
- production deploy passes
- public route responds
- required env vars recreated
- old project kept as fallback until next dependent app is migrated

