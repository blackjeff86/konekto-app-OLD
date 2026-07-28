# Visible Runtime Branding Cleanup

Last updated: 2026-07-27

## Objective

Finish the visible Sevvn branding cleanup for active runtime and operator-facing surfaces without doing the high-risk structural rename.

## Scope Completed

This cleanup was limited to what users or operators can actually see during the current pilot phase.

### Active operator surfaces

Confirmed aligned with Sevvn:

- admin login page
- admin shell/sidebar
- admin web title and manifest
- portal support surface
- official site/login links used by portal and admin

### Guest-facing runtime surfaces

Updated to Sevvn:

- Flutter app runtime title in `apps/konekto_mobile/lib/main.dart`
- pre-claim home wordmark in `apps/konekto_mobile/lib/app/home_konekto/home_konekto_page.dart`
- mobile web title/description/apple title in `apps/konekto_mobile/web/index.html`
- mobile web install manifest in `apps/konekto_mobile/web/manifest.json`
- iOS display name and bundle name in `apps/konekto_mobile/ios/Runner/Info.plist`

## What This Means

As of 2026-07-27, the active pilot-facing surfaces no longer depend on visibly presenting the old Konekto brand for normal usage.

The remaining `konekto` occurrences are mostly:

- folder names
- package/import identifiers
- class names like `KonektoBrand`
- comments and migration references
- native/internal metadata outside the current pilot-facing surface review

Those belong to the later structural rename and native rename phases, not to this pilot-hardening task.

## Operational Conclusion

Task 13 is satisfied when:

- operator-facing active pages present Sevvn visibly
- guest entry/runtime metadata present Sevvn visibly
- the remaining old-brand references are technical debt, not pilot-facing branding leakage

That condition is now met.
