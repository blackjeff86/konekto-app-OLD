# Todo: Sevvn 30-Day Pilot Hardening

Plano completo em `tasks/plan-sevvn-30-day-pilot.md`.

## Phase 1: Reality Control
- [x] Task 1: Force API-first pilot behavior in the guest app
- [x] Task 2: Audit remaining demo and fallback runtime paths
- [x] Task 3: Freeze the official pilot module scope in code/docs
- [ ] Checkpoint: pilot truth path reviewed and approved

## Phase 2: Security And Observability
- [x] Task 4: Add rate limiting to sensitive public/auth endpoints
- [x] Task 5: Add correlation IDs and structured request logging
- [x] Task 6: Add audit logging for privileged platform-admin mutations
- [x] Task 7: Reduce `GET /api/hotels/:hotelId` to a guest-safe contract
- [ ] Checkpoint: security hardening reviewed and approved

## Phase 3: Product Truth
- [x] Task 8: Validate pilot modules against real persisted flows
- [x] Task 9: Execute template compatibility checks for the five templates
- [x] Task 10: Align public/internal product claims with actual readiness
- [ ] Checkpoint: readiness truth reviewed and approved

## Phase 4: Pilot Rehearsal
- [x] Task 11: Verify the onboarding-to-guest-use journey for one pilot hotel
- [x] Task 12: Retire `apps/konekto_site` from the active runtime path
- [x] Task 13: Finish the visible Sevvn runtime/admin branding cleanup
- [ ] Checkpoint: pilot-ready flow reviewed and approved

## Remaining To Really Close
- [ ] Approve API-mode pilot truth path and asset-mode exclusion
- [ ] Approve fallback-path classification and pilot module scope review
- [ ] Approve visible abuse protection on the intended public/auth routes
- [ ] Execute one live representative hotel rehearsal end to end (`Konekto Hotel`)
- [ ] Confirm official Sevvn support/contact channels
- [ ] Decide what to do with the root legacy Vercel project
