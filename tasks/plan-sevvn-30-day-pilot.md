# Implementation Plan: Sevvn 30-Day Pilot Hardening

## Overview

This plan breaks the next delivery phase into small, verifiable tasks aimed at pilot readiness instead of feature expansion. The main principle is simple: one source of truth, no silent demo fallback, no false module claims, and enough operational visibility to support a real hotel pilot.

## Architecture Decisions

- Treat the backend as the source of truth and make the guest app prove it.
- Keep the current app structure stable during this phase; do not combine hardening with a structural rename.
- Prioritize shared runtime risks first: fallback paths, rate limiting, correlation IDs, auditability, and guest-safe public payloads.
- Validate pilot readiness with a representative hotel journey rather than broad catalog coverage.

## Task List

### Phase 1: Reality Control

- [x] Task 1: Force API-first pilot behavior in the guest app.
- [x] Task 2: Audit remaining demo and fallback runtime paths.
- [x] Task 3: Freeze the official pilot module scope in code/docs.

### Checkpoint: Reality Control

- [ ] Pilot builds do not silently validate against asset data.
- [ ] Every remaining fallback path is documented and intentionally classified.
- [ ] Pilot module scope is explicit and reviewed.

### Phase 2: Security And Observability

- [x] Task 4: Add rate limiting to sensitive public/auth endpoints.
- [x] Task 5: Add correlation IDs and structured request logging.
- [x] Task 6: Add audit logging for privileged platform-admin mutations.
- [x] Task 7: Reduce `GET /api/hotels/:hotelId` to a guest-safe contract.

### Checkpoint: Security

- [ ] Auth/public endpoints have visible abuse protection.
- [x] Request tracing exists across the active stack.
- [x] Sensitive admin actions leave an audit trail.
- [x] Public hotel config reads are reduced to a guest-safe contract.

### Phase 3: Product Truth

- [x] Task 8: Validate pilot modules against real persisted flows.
- [x] Task 9: Execute template compatibility checks for the five templates.
- [x] Task 10: Align public/internal product claims with actual readiness.

### Checkpoint: Product Truth

- [x] Pilot-ready modules are clearly separated from partial/UI-only ones.
- [x] Shared pilot scenarios work across templates.
- [x] Public claims no longer overstate current reality.

### Phase 4: Pilot Rehearsal

- [x] Task 11: Verify the onboarding-to-guest-use journey for one pilot hotel.
- [x] Task 12: Retire `apps/konekto_site` from the active runtime path.
- [x] Task 13: Finish the visible Sevvn runtime/admin branding cleanup.

### Checkpoint: Pilot Ready

- [ ] One representative hotel scenario works end to end.
- [x] The legacy static site is no longer operationally required.
- [x] Active surfaces are coherent enough for pilot-facing use.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Demo paths hide regressions | High | Make API-first behavior the first deliverable |
| Scope expands into non-pilot modules | High | Freeze module scope before implementation |
| Security work is deferred | High | Put hardening before rename/refactor work |
| Template parity is assumed, not proven | Medium | Validate with shared scenarios and representative data |

## Open Questions

- Which support channels should become the official Sevvn contacts?
- When should the legacy root Vercel project be archived or ignored?

## Remaining To Truly Close

See:

- [pilot-remaining-items-2026-07-27.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/pilot-remaining-items-2026-07-27.md)
