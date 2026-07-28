# Security Review

Last updated: 2026-07-26

## Scope

This review covers the current repository state before further implementation. It is not a penetration test. It is a source-level architectural review focused on:

- authentication
- authorization
- multi-tenancy
- data exposure
- uploads
- integrations
- observability and auditability

## Executive Summary

The codebase already contains meaningful security controls:

- separate auth paths for staff, guest, platform admin, and integrations
- route-level hotel ownership checks in many operational endpoints
- hashed integration API keys
- guest session revalidation against database
- protected access for private hotel content like Wi-Fi settings

However, the platform is not yet pilot-hardened. The biggest gaps are:

1. no visible rate limiting
2. current structured logging is only a baseline, not yet a full redaction-aware audit/observability model
3. guest app asset mode bypasses true backend-enforced reality

## Findings

### High

#### 1. Guest app still contains a local asset fallback mode

Reference:

- [tenant_repository_provider.dart](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_mobile/lib/data/tenant_repository_provider.dart:1)

Risk:

- The product can appear healthy in demo or QA while bypassing backend truth, tenancy, and operational controls.
- This is not a direct exploit by itself, but it is a serious production-readiness and trust risk.

Impact:

- false sense of security
- false validation of pilot scope
- possible divergence between app behavior and backend rules

Recommendation:

- pilot builds must stay on API mode
- asset mode must remain explicitly non-production

#### 2. No visible rate-limiting layer on sensitive public/auth endpoints

Examples:

- guest claim
- auth login
- public hotel lookups
- image proxy
- integration endpoints

Risk:

- brute-force attempts
- enumeration
- abuse of public endpoints

Recommendation:

- add rate limiting at API edge or application layer
- at minimum protect login, guest claim, image proxy, and public hotel/content reads

Current status:

- initial in-app rate limiting was added on July 26, 2026 for staff login, platform-admin login, guest claim, image proxy, public hotel directory/config/content reads, and promotions
- this closes the highest-priority immediate gap, but it is still an in-memory application-layer control rather than a distributed edge-grade limiter

#### 3. Structured logging and correlation IDs were missing and are now partially in place

Risk:

- difficult incident response
- hard to trace multi-step failures
- weak auditability across guest, hotel staff, and integrations

Recommendation:

- standardize request logging with `correlationId`, `tenantId`, `userId`, `endpoint`, `duration`, `status`

Current status:

- on July 26, 2026, the API gained request-level `x-correlation-id` propagation plus structured JSON logging for the highest-priority auth, public config, content, promotions, and image-proxy routes
- the current baseline logs `correlationId`, client IP, method, path, route label, surface, duration, and status
- this closes the immediate tracing gap, but tenant/user enrichment and a formal redaction policy still need to be added before observability expands across the full API

### Medium

#### 4. Public hotel config exposure was reduced, but still deserves contract discipline

Reference:

- [route.ts](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/app/api/hotels/[hotelId]/route.ts:1)

Current behavior:

- public `GET /api/hotels/:hotelId` now returns a guest-safe payload, while plan/template entitlement metadata is only returned when the caller is authenticated staff from the same hotel

Risk:

- unnecessary exposure of hotel internals
- easier reconnaissance for attackers

Recommendation:

- split guest-safe config from portal/admin-safe config
- expose only what the guest app actually needs

Current status:

- on July 26, 2026, `GET /api/hotels/:hotelId` was reduced so anonymous/public callers only receive guest-facing config plus resolved modules
- internal entitlement metadata like `plan` and `allowedTemplates` no longer ride along on public reads; the portal now fetches the enriched payload with a staff bearer token
- this closes the most visible reconnaissance issue on that endpoint, though future contract review should keep pruning unused guest-facing keys from `Hotel.config`

#### 5. Critical business payloads still rely on permissive JSON blobs

References:

- `Hotel.config`
- `HotelContent.data`

Risk:

- weaker schema guarantees
- harder security validation
- accidental exposure of sensitive or malformed data

Recommendation:

- progressively formalize high-value contracts
- validate document-specific shapes server-side

#### 6. Platform-admin audit logging is now in place for the highest-impact cross-tenant mutations

Examples:

- create hotel
- change plan
- assign preset
- change extra modules
- suspend tenant

Risk:

- low forensic visibility
- difficult rollback reasoning
- compliance weakness

Recommendation:

- add administrative audit table and mutation logging

Current status:

- on July 26, 2026, the API gained a dedicated `PlatformAdminAuditLog` model plus append-only writes for the highest-impact `platform-admin` mutations currently used in onboarding and commercial control
- the first audited actions are hotel creation, courtesy extra-module changes, and subscription updates
- each audit row stores admin identity, hotel/target scope, correlation ID, client IP, action name, and a sanitized payload without transient secrets like the generated temporary password
- this closes the immediate pilot gap for privileged mutation traceability, but the database migration still needs to be applied in each environment before deployment

### Low / Observational

#### 7. Guest stay expiration is reactive, not scheduled

Reference:

- [auth-guard.ts](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/lib/auth-guard.ts:1)
- [stay-expiration.ts](/abs/path/C:/ProjetosFlutter/konekto_app/apps/konekto_api/lib/stay-expiration.ts:1)

Risk:

- stale active sessions can persist until touched

Recommendation:

- acceptable for early phase, but better with scheduled sweep or job support

#### 8. Integration provider model is still tactical

Risk:

- provider-specific behavior can spread
- secret handling and retry logic can become inconsistent over time

Recommendation:

- consolidate provider abstraction before adding multiple PMS/ERP connectors

## Authentication Review

### Staff

Strengths:

- JWT
- role-based checks
- hotel ownership checks in routes

Gaps:

- no visible login throttling
- no visible session device tracking

### Guest

Strengths:

- per-guest access code
- token issuance after claim
- DB revalidation on protected flows
- revoked/expired stay logic exists

Gaps:

- guest claim endpoint needs rate limiting
- access code enumeration protection is not visible

### Platform admin

Strengths:

- separate auth path
- explicit cross-tenant power

Gaps:

- no visible audit log for privileged actions

## Authorization And Multi-Tenancy Review

Strengths:

- many endpoints check `staff.hotelId === route hotelId`
- guest routes re-resolve guest from DB
- private `guestInfo` content is protected

Gaps:

- tenancy is enforced mostly in application code, not data layer policy
- public config endpoints broaden surface area
- mobile asset mode weakens confidence in tenant isolation during testing

## Upload Review

Observed:

- hotel uploads route exists
- Vercel Blob integration exists

What still needs verification or hardening:

- exact MIME restrictions
- max file size
- image-only enforcement
- external URL trust boundaries after upload
- malware scanning strategy, if any

## Secret Handling Review

Observed:

- JWT secret expected from environment
- integration API keys hashed in DB
- webhook secret stored

Gaps:

- no central secret rotation/audit story visible in repo
- no secret exposure scan documented

## Data Privacy Review

The system handles:

- guest identity
- contact details
- room assignments
- stay dates
- payment-related references
- hotel credentials and integration state

Privacy risks:

- overbroad public config
- insufficient structured logging policy could accidentally log PII later
- JSON blobs can accumulate mixed-sensitivity data

Recommendation:

- define a logging redaction policy before expanding observability

## Immediate Security Actions Recommended Before Pilot

1. Keep guest app pilot builds on API mode only and avoid using asset mode as readiness evidence.
2. Add rate limiting to guest claim, login, image proxy, and public lookups.
3. Add stricter server-side validation for key `HotelContent` documents.

## Overall Rating

Current state:

- good directional security foundations
- not yet hardened enough for a production-grade cross-tenant pilot without focused security work

Recommended release position:

- acceptable for controlled staging after hardening
- not yet acceptable for externally exposed pilot traffic without the immediate actions above
