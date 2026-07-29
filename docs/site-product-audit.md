# Site Product Audit

Last updated: 2026-07-27

## Goal

Map what the public site can safely claim based on the current repository state.

## 1. Product Surfaces Confirmed In Repo

Confirmed and real:

- guest app (`apps/konekto_mobile`)
- hotel portal (`apps/sevvn_portal_next`)
- Sevvn admin / platform admin (`apps/sevvn_admin`)
- backend platform (`apps/sevvn_api`)
- institutional site (`apps/sevvn_site_next`)
- real login flow for hotel staff

## 2. Plan And Template Reality

Confirmed:

- plans: `Essential`, `Premium`, `Enterprise`
- templates: `Aura`, `Bosque`, `Elite`, `Pulse`, `Horizon`
- plan/template gating exists in code through `plan-presets.ts`

Commercially safe claims:

- templates define visual identity
- plans define allowed templates and module availability
- the same platform serves multiple hotel profiles

## 3. Modules Confirmed As Implemented In Catalog

Catalog source:

- `apps/sevvn_api/lib/module-catalog.ts`

Marked `implemented: true`:

- Home
- Informações da hospedagem
- Serviços
- Reservas
- Mensagens
- Perfil
- Notificações básicas
- Room Service
- Restaurantes
- Spa
- Passeios
- Carteira Digital
- Promoções
- Programa de Fidelidade

## 4. Important Readiness Caveat

Marked `implemented` is not the same as public-production-ready.

Conservative public interpretation after the July 27, 2026 validation pass:

- Available: room service, restaurants, tours/passeios, spa as service category, guest messaging, stay information, notifications, branding/templates, module gating, hotel portal operations, platform admin, PMS-style integration layer
- Demonstrable but still maturing: loyalty, wallet, broader financial abstraction, support flows, integration management, partner-linked service items
- Controlled pilot-safe capabilities: promotions, spa, tours, five-template compatibility for the shared guest flows
- Not yet available as finished public features: digital check-in, digital check-out, interactive map, multilingual chat, FAQ module, help center, smart notifications, concierge module, events module, laundry, kids club, pools, gym, transport, parking

## 5. Hotel Portal Reality

Confirmed in repo:

- hotel config and branding
- module toggles
- appearance/template selection
- integrations management
- staff management
- guests, stays, rooms, orders, services, coupons, support, dashboard stats

Safe public claim:

- Sevvn Hotel is a real operational portal, not just a concept

## 6. Platform Admin Reality

Confirmed:

- cross-tenant admin login
- tenant listing
- tenant creation
- subscription updates
- support inbox

Safe public claim:

- Sevvn has a central platform administration layer

## 7. Integrations Reality

Confirmed:

- inbound reservation sync endpoints
- inbound menu category sync
- inbound menu item sync
- hotel integration credentials
- outbound webhook dispatch on orders

Safe public claim:

- Sevvn is prepared for PMS / hotel-system integrations

Careful wording:

- say "integrações com sistemas hoteleiros e PMS"
- do not claim broad certified coverage of major PMS vendors unless explicitly validated

## 8. Partner / Network Reality

Confirmed in code:

- `Partner` model exists
- partner CRUD routes exist
- service items can link to partners
- partner payment mode exists

Not confirmed as fully launched network:

- no full public partner marketplace flow
- no dedicated partner portal
- no network-scale distribution layer exposed publicly

Safe public claim:

- Sevvn Network is in development
- Sevvn is already building the data and service foundations for partner participation

## 9. Roadmap Reality

Available now:

- modular platform base
- templates
- hotel portal
- platform admin
- real login
- room service / restaurant / tours / spa service structures
- guest messaging / notices / bookings-related flows
- integrations foundation

In development:

- broader module coverage
- partner network layer
- expansion of operational and revenue features
- richer hotel-side management and automation

Coming soon:

- digital check-in / check-out
- interactive map
- smart notifications
- multilingual chat
- expanded help / FAQ experiences
- full Sevvn Network experience

## 10. Public Narrative Recommendation

The site can honestly say:

- Sevvn is already a concrete platform
- the guest app is one interface within the platform
- hotels can operate branded guest journeys on top of a modular architecture
- new modules can be activated over time
- integrations and partner-network foundations already exist
- the same pilot-safe guest flows can run across the five current templates

The site should not say:

- every listed roadmap feature is ready today
- the partner network is fully launched
- digital wallet and loyalty are fully mature across all real-world flows
- every template-specific surface is already parity-validated

