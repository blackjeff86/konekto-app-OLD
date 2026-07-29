# Sevvn Site Technical Plan

Last updated: 2026-07-26

## 1. Content Architecture

Create a structured content layer under `apps/sevvn_site_next/content/`:

- `brand.ts`
- `navigation.ts`
- `products.ts`
- `modules.ts`
- `roadmap.ts`
- `plans.ts`
- `partners.ts`
- `use-cases.ts`
- `faq.ts`

Recommended shared public types:

- `ProductStatus = "available" | "in-development" | "coming-soon"`
- `Audience = "hotel" | "guest" | "partner" | "network" | "enterprise"`

## 2. Components To Reuse

- `Section`
- `SectionHeading`
- `Logo`
- `Badge`
- `ComingSoonSpinner`
- `PlanCard` if adapted to the new narrative

## 3. Components To Refactor

- `SiteHeader`
- `SiteFooter`
- `Hero`
- `HowItWorks`
- `ModularPlatform`
- `Templates`
- `ModuleGrid`
- `ContinuousEvolution`
- `Pricing`
- `FoundingClients`
- `Faq`
- `FinalCta`

## 4. New Components Likely Needed

- `PlatformVision`
- `HotelBenefits`
- `GuestJourney`
- `EcosystemDiagram`
- `ProductSurfaces`
- `PublicRoadmapSummary`
- `PartnerNetwork`
- `UseCases`
- `StatusPill`
- `ContactForms`

## 5. New Routes Likely Needed

- `/plataforma`
- `/hoteis`
- `/parceiros`
- `/recursos`
- `/templates`
- `/planos`
- `/roadmap`
- `/sobre`
- `/contato`

## 6. Public Status Source Of Truth

Create a central file:

- `content/roadmap.ts`

This file should map:

- `publicFeatureId`
- `displayName`
- `status`
- `audience`
- `category`
- `planAvailability?`
- `description`

Marketing sections must consume this file instead of duplicating status manually.

## 7. Form Strategy

Preferred future state:

- distinct forms for hotel demo, partner interest and enterprise contact

Current safe recommendation:

- first implement validated static forms with documented submission handling
- if no backend lead endpoint exists yet, use a temporary safe capture strategy and document it before deploy

## 8. Login Preservation Strategy

Allowed:

- brand updates
- metadata updates
- layout polish
- accessibility improvements

Not allowed without explicit validation:

- auth payload changes
- endpoint changes
- redirect contract changes
- token handling changes

## 9. SEO Work

- route-level metadata
- Open Graph
- canonical
- sitemap
- robots
- structured data where useful
- alt text cleanup
- remove any public `Konekto` naming

## 10. Risks

- overselling unfinished modules
- duplicating feature status in multiple content files
- making the Home too long and repetitive
- adding heavy client-side logic to what should stay static
- accidentally breaking `/login`

## 11. Deployment Strategy

1. content architecture and static pages first
2. Home refactor
3. internal pages
4. forms
5. login visual review
6. lint/build/test
7. staging QA
8. production deploy with rollback point

## 12. Recommended Execution Order After Approval

1. content architecture and roadmap source
2. header/footer/metadata/navigation
3. Home repositioning
4. partner and roadmap pages
5. hotels/resources/templates/plans/about/contact pages
6. forms and conversion wiring
7. QA and deploy

