# Pilot Remaining Items

Last updated: 2026-07-27

## Objective

Record the remaining work required to close the Sevvn pilot for real, without losing the distinction between:

- hardening work already implemented
- validations still missing
- environment-dependent checks
- later structural rename work that should not block the pilot

## Current State

By 2026-07-27, the implementation tasks in the active 30-day pilot plan are complete through Task 13.

What is still open is not broad feature work. It is mostly final validation, explicit review, and a few operational confirmations.

## Remaining To Close The Pilot For Real

### 1. Final API-mode proof for the guest app

Status:

- partially satisfied in code
- still pending as an explicit sign-off item

What still needs to happen:

- run a pilot-safe build of the guest app in `APP_RUNTIME_MODE=api`
- confirm the validation path does not silently rely on asset mode
- capture the exact build/runtime evidence used for approval

Why it is still open:

- the code and docs now define API-first as the official path
- but the checkpoint still expects explicit approval that pilot validation is not happening against asset data

Related open checkpoint items:

- `Pilot builds do not silently validate against asset data`
- `Checkpoint: pilot truth path reviewed and approved`

### 2. Final fallback-path review sign-off

Status:

- documentation exists
- explicit review/approval still pending

What still needs to happen:

- review the documented fallback paths one final time
- confirm which are acceptable as controlled dev/demo fallback
- confirm which must stay out of pilot validation

Why it is still open:

- the audit and scope freeze were completed
- but the plan still treats this as needing an explicit reviewed state

Related open checkpoint items:

- `Every remaining fallback path is documented and intentionally classified`
- `Pilot module scope is explicit and reviewed`

### 3. Visible abuse-protection confirmation

Status:

- implemented in code
- not yet closed as an approval checkpoint

What still needs to happen:

- confirm the sensitive public/auth surfaces currently protected by rate limiting are the intended pilot set
- optionally capture one short review note naming the protected routes

Why it is still open:

- rate limiting was added
- but the plan still keeps `Auth/public endpoints have visible abuse protection` unchecked until review/acceptance

Related open checkpoint items:

- `Auth/public endpoints have visible abuse protection`
- `Checkpoint: security hardening reviewed and approved`

### 4. One live representative hotel rehearsal

Status:

- tenant chosen and structurally documented
- still not executed as a live operational sign-off

What still needs to happen:

- use the chosen canonical tenant: `Konekto Hotel`
- run the rehearsal against a real environment with real credentials/data
- confirm the path works end to end beyond code inspection and desk validation

Why it is still open:

- Task 11 defined the canonical flow and evidence
- product has now chosen `Konekto Hotel` as the canonical tenant
- but the final checkpoint still expects one representative hotel scenario to actually work end to end

Related open checkpoint items:

- `One representative hotel scenario works end to end`
- `Checkpoint: pilot-ready flow reviewed and approved`

### 5. Support/contact finalization

Status:

- partially aligned
- still open as an operational decision

What still needs to happen:

- confirm the official Sevvn support/contact channels to use everywhere
- then normalize any remaining temporary channels across runtime and public copy

Why it is still open:

- this is still listed in the plan open questions
- it affects the quality of a true pilot-ready handoff

### 6. Root legacy Vercel decision

Status:

- not blocking the pilot
- still open as infrastructure cleanup

What still needs to happen:

- decide whether the root legacy Vercel project should be archived, ignored, or replaced later by a canonical root `sevvn` project

Why it is still open:

- the active apps already have canonical Sevvn projects
- but the plan still carries the root project as an open operational question

## Explicitly Deferred For Later

These items still matter, but they should not be confused with remaining pilot-hardening blockers.

### Structural rename

- folder renames
- package name renames
- import-root renames
- class names like `KonektoBrand`

### Native/platform rename completion

- remaining native metadata outside the visible pilot-facing scope
- executable/internal product identifiers

### Full legacy package deletion

- physically deleting `apps/konekto_site`
- removing old fallback infra only after external dependency confirmation

## Recommended Re-entry Order

When we come back to close the pilot fully, the cleanest order is:

1. confirm the canonical pilot hotel/tenant
2. run the live end-to-end rehearsal in API mode
3. record the review note for fallback-path truth and abuse protection
4. close the remaining checkpoint approvals in the plan
5. then decide on root legacy Vercel handling and later structural rename timing

## Conclusion

The remaining work is now small and concrete.

The biggest gap is no longer implementation breadth. It is final proof, approval, and operational confirmation.
