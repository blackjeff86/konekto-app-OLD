# Site Repositioning Audit

Last updated: 2026-07-26

## 1. Current Site Surfaces

Primary institutional app:

- `apps/sevvn_site_next`

Legacy parallel surface:

- `apps/konekto_site`

Functional login kept active:

- `apps/sevvn_site_next/app/login/page.tsx`
- `apps/sevvn_site_next/app/login/LoginForm.tsx`

## 2. Current Home Structure

Current `/` composition in `apps/sevvn_site_next/app/page.tsx`:

1. `SiteHeader`
2. `Hero`
3. `HowItWorks`
4. `ModularPlatform`
5. `Templates`
6. `ModuleGrid`
7. `ContinuousEvolution`
8. `Pricing`
9. `FoundingClients`
10. `Faq`
11. `FinalCta`
12. `SiteFooter`

## 3. Current Positioning Problems

Main issue:

- the site already says "platform", but it still communicates mostly as a configurable White Label app offer

Specific positioning gaps:

- the hero is too abstract and does not show the operational ecosystem behind the guest app
- there is no dedicated story for hotel teams, partners, or enterprise groups
- the hotel portal and Sevvn admin are not presented as first-class product surfaces
- integrations exist in the product, but they are barely visible in the commercial narrative
- the future Sevvn Network is not positioned strategically
- the roadmap is not exposed with honest public statuses
- plans still feel closer to app packages than platform evolution tiers

## 4. Current Reusable Elements

Reusable and worth keeping:

- `components/layout/SiteHeader.tsx`
- `components/layout/SiteFooter.tsx`
- `components/ui/Section.tsx`
- `components/ui/SectionHeading.tsx`
- `components/ui/Badge.tsx`
- `components/ui/ComingSoonSpinner.tsx`
- login flow structure in `app/login`

Reusable with heavy content refactor:

- `Hero`
- `HowItWorks`
- `ModularPlatform`
- `ModuleGrid`
- `Pricing`
- `FoundingClients`
- `Faq`
- `FinalCta`

Likely to be replaced or split:

- `Templates` in its current minimal form
- current one-file `plans.ts` and `faq.ts` strategy, which is too small for the new content architecture

## 5. Elements That Should Be Removed Or Demoted

- any public narrative that frames Sevvn as only an app builder
- any remaining `@konekto.app` public CTA target
- hardcoded marketing claims that are not mapped to product reality
- the current shallow "How it works" if it remains only a 6-step commercial strip without platform context

Not to remove:

- `/login` contract and flow
- compatibility handling for existing auth redirect behavior

## 6. Login Flow Review

Current state:

- login is already moved to `apps/sevvn_site_next/app/login`
- it posts to the real API auth endpoint
- it redirects to the real hotel portal with token query string
- visible branding already says `Sevvn`

Risk level:

- high if we change behavior
- low if we change only content, accessibility, layout, and metadata around it

Conclusion:

- login must be preserved as a functional surface and only visually improved if needed

## 7. Current SEO / Metadata State

Positive:

- `app/layout.tsx` already uses Sevvn-oriented metadata
- login metadata already says `Sevvn`

Gaps:

- content depth is still too shallow for the new platform positioning
- there is no visible content architecture for roadmap, partners, hotels, or platform pages
- likely missing dedicated schema, sitemap strategy, and route-level metadata for the expanded sitemap

## 8. Performance / Architecture State

Positive:

- the institutional site is static-content friendly
- current homepage does not depend on live API rendering
- content is already separated from some UI through `content/*.ts`

Risks:

- adding too much hardcoded content directly in sections will make future updates hard
- building roadmap/status logic ad hoc in components will create drift
- large image-heavy hero sections can hurt performance if not carefully handled

## 9. Main Recommendation

Rebuild the institutional content architecture around:

1. platform narrative first
2. public status honesty second
3. hotels and partners as distinct journeys
4. the guest app as one interface inside a larger operational system

