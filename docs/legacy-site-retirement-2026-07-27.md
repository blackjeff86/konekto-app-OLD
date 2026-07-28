# Legacy Site Retirement

Last updated: 2026-07-27

## Objective

Retire `apps/konekto_site` from the active Sevvn runtime path without breaking old links.

## Result

As of 2026-07-27, `apps/konekto_site` is no longer treated as an active product surface.

Its new role is:

- compatibility redirect for old institutional links
- compatibility redirect for old `/login.html` links
- historical asset/archive package only

The active official surface is:

- `apps/konekto_site_next`

## Runtime Decision

The official destinations are now:

- site: `https://sevvn-site.vercel.app`
- login: `https://sevvn-site.vercel.app/login`

The legacy package now redirects:

- `apps/konekto_site/index.html` -> `https://sevvn-site.vercel.app`
- `apps/konekto_site/login.html` -> `https://sevvn-site.vercel.app/login`

## Verification

The active app configs already point to the new official surface:

- `apps/konekto_portal_next/lib/siteConfig.ts`
- `apps/konekto_admin/lib/site_config.dart`

The legacy runtime dependency was reduced by:

- replacing the old static landing page with a redirect shell
- updating the legacy login redirect to the official Next.js login route
- updating portal auth comments so the codebase no longer documents the legacy HTML as the real login surface

## Operational Meaning

This does not delete `apps/konekto_site` yet.

It means:

- no active Sevvn flow should depend on that package to work
- if an old bookmark or deployment still reaches it, the user is forwarded to the official site
- future cleanup can archive or remove the package with much lower risk

## Remaining Follow-Up

Before final deletion of `apps/konekto_site`, the team should still confirm:

- no external material still depends on its static assets directly
- no old Vercel project still needs to stay public as a fallback

## Conclusion

Task 12 is satisfied once the legacy package is reduced to compatibility behavior and no longer acts as an operationally required site.
