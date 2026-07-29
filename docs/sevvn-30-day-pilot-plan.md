# Sevvn 30-Day Pilot Plan

Last updated: 2026-07-26

## Overview

This plan turns the current Sevvn codebase into a controlled 30-day pilot platform.

The strategy is not to expand breadth. The repository already contains enough product surface for a pilot. The real work now is:

- remove false signals caused by demo and fallback paths
- harden the active runtime paths
- prove a realistic pilot scope across API, portal, guest app, and admin
- create enough operational visibility to support real external usage

This plan is based on:

- [platform-current-state.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/platform-current-state.md)
- [module-readiness-matrix.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/module-readiness-matrix.md)
- [security-review.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/security-review.md)
- [rebrand-plan.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/rebrand-plan.md)
- [pilot-scope-freeze.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/pilot-scope-freeze.md)

## Architecture Decisions

- The 30-day window is treated as a pilot-hardening phase, not a feature-expansion phase.
- Pilot scope is limited to modules already closest to reality: room service, restaurant, spa, tours, messages, basic notifications, stays, guests, and hotel operations.
- Guest app API mode must become the pilot truth path; asset mode can remain only as an explicitly non-production fallback.
- Security and observability work moves ahead of structural rename work.
- The admin rewrite to Next.js is not part of this 30-day pilot. For this phase, the Flutter admin remains operational and is hardened only where necessary.

## Pilot Goal

At the end of 30 days, Sevvn should be able to support a controlled pilot hotel flow with:

- hotel onboarding through Sevvn Admin
- subscription/template/module setup
- room and stay operations in the portal
- guest claim and authenticated app usage against live backend data
- room service and restaurant flows working on real persisted data
- messaging and basic notifications working end to end
- clear visibility into what is truly enabled, what is pilot-ready, and what is still intentionally disabled

## Non-Goals For This Window

- no broad structural rename of folders and package roots
- no native mobile package rename
- no production-grade launch of wallet, loyalty, digital check-in/out, interactive map, or smart notifications
- no rewrite of `apps/sevvn_admin` to Next.js
- no attempt to make every catalog module public-facing and operational this month

## Task List

### Phase 1: Reality Control

- [x] Task 1: Force the guest app pilot path to API-first behavior.
- [x] Task 2: Audit and document every remaining runtime fallback that can mask production regressions.
- [x] Task 3: Define and codify the official pilot module set across API, portal, mobile, and admin.

### Checkpoint: Reality Control

- [ ] Pilot scope is explicit and written.
- [ ] Guest app production/pilot path no longer silently validates against asset data.
- [ ] Team can explain which modules are in pilot, behind flags, or out of scope.

### Phase 2: Security And Observability Hardening

- [ ] Task 4: Add rate limiting to sensitive public/auth endpoints.
- [ ] Task 5: Add request correlation IDs and structured logs for active routes.
- [ ] Task 6: Introduce an audit trail for sensitive platform-admin mutations.
- [ ] Task 7: Reduce the public hotel payload to a guest-safe contract.

### Checkpoint: Security Hardening

- [ ] Login, guest claim, image proxy, and public hotel reads are protected by rate limiting.
- [ ] Requests can be traced end to end with correlation IDs.
- [ ] Sensitive admin changes produce an auditable trail.

### Phase 3: Module And Template Validation

- [ ] Task 8: Validate pilot modules against real data paths, not catalog claims.
- [ ] Task 9: Build a compatibility pass for the five guest templates using shared pilot scenarios.
- [ ] Task 10: Separate pilot-ready flows from partial/UI-only flows in product-facing documentation and internal configs.

### Checkpoint: Product Truth

- [ ] The same pilot dataset is known to work across the five templates.
- [ ] Pilot-ready modules are distinguished from partial/demo-only ones.
- [ ] No stakeholder-facing material implies that unready modules are fully live.

### Phase 4: Operational Readiness

- [ ] Task 11: Finalize tenant onboarding and hotel setup checklist in Sevvn Admin.
- [ ] Task 12: Verify end-to-end pilot flow for one representative hotel scenario.
- [ ] Task 13: Retire the legacy static site from the active runtime path.
- [ ] Task 14: Close the remaining visible Sevvn rebrand gaps in active operator surfaces.

### Checkpoint: Pilot Ready

- [ ] A hotel can be configured, operated, and used by guests through the active stack.
- [ ] Legacy `apps/konekto_site` is no longer required by any live flow.
- [ ] Runtime branding is coherent enough for pilot-facing usage.

## Ordered Work Queue

### Wave 1

1. guest app API-first enforcement
2. pilot module definition
3. fallback-path audit

### Wave 2

1. rate limiting
2. correlation IDs and structured logs
3. public hotel payload reduction
4. admin audit trail

### Wave 3

1. module readiness verification
2. template compatibility validation
3. pilot documentation alignment

### Wave 4

1. end-to-end pilot rehearsal
2. legacy site retirement
3. visible branding cleanup

## Risks And Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Asset-mode guest app still masks backend regressions | High | Make API mode the pilot truth path first |
| Pilot scope drifts into unready modules | High | Freeze an explicit pilot module list and keep the rest behind flags |
| Hardening work is postponed in favor of cosmetic work | High | Execute security and observability before structural renames |
| Template compatibility is assumed instead of verified | Medium | Run shared pilot scenarios across all five templates |
| Admin app becomes a bottleneck because it is still Flutter | Medium | Limit this phase to operational hardening, not a rewrite |

## Open Questions

- Which exact hotel profile should be used as the canonical pilot rehearsal tenant?
- Which support/contact e-mail addresses should replace any remaining temporary channels?
- Should the root legacy Vercel project also receive a canonical `sevvn` counterpart, or can it be left as historical residue until structural rename?

## Recommended Next Build Step

Move into Phase 2:

- add rate limiting to the sensitive public/auth surfaces
- introduce correlation IDs and structured logging
- tighten the guest-safe public payloads before expanding any pilot exposure

