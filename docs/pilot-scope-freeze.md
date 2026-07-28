# Sevvn Pilot Scope Freeze

Last updated: 2026-07-26

## Objective

Freeze the official pilot scope for the current Sevvn platform so that product, engineering, operations, sales, and public-facing materials all describe the same thing.

This document is the operational source of truth for:

- what is officially inside the 30-day pilot scope
- what can be demonstrated only in controlled test conditions
- what must stay disabled, behind flags, or outside the pilot narrative

## Scope Principle

The pilot is not a broad launch of the full Sevvn vision.

It is a controlled hospitality operations pilot built on the strongest parts of the current repository:

- real backend data
- real hotel operations
- real guest claim and stay usage
- real room service and restaurant flows
- real message and notice flows

Anything that depends on demo-only screens, mock balances, catalog-only modules, or asset-mode validation is outside the official pilot scope.

## Official Pilot Scope

### Included

- hotel onboarding and cross-tenant setup through Sevvn Admin
- hotel subscription, template, and enabled-module setup
- hotel staff access and operational usage through the portal
- room management
- stay creation and active stay operations
- guest claim with real backend validation
- guest access to stay information and Wi-Fi
- room service ordering
- restaurant reservation/table availability flows
- generic hotel services that are already backed by the real service model
- guest/staff messaging
- basic notices and unread counters
- hotel branding, service configuration, staff management, and integrations in the active operational stack

### Included With Caution

These are allowed in the pilot only when treated as controlled, validated capabilities rather than broad marketing promises.

- spa services through the generic service model
- tours through the generic service model
- promotions and coupons when presented as operationally available but still under controlled pilot usage
- modular template selection, as long as the same hotel scenario is validated against the chosen template

### Out Of Official Pilot Scope

- loyalty as a live value-bearing feature
- digital wallet as a live financial module
- digital check-in
- digital check-out
- interactive map
- multilingual chat
- concierge as a real live module
- service reviews
- smart notifications
- partner network as a fully launched product
- partner portal
- certified PMS connector claims
- full in-app payment coverage for every guest journey

## Module Classification

### Pilot-Ready Core

- `hotel_info`
- `messages`
- `room_service`
- `restaurant`

### Pilot-Ready With Hardening/Validation

- `home`
- `services`
- `bookings`
- `profile`
- `basic_notifications`
- `spa`
- `tours`
- `promotions`

### Test-Only / Partial / Behind Flags

- `events`
- `payments`
- `loyalty`
- `digital_wallet`

### Not In This Pilot Window

- `interactive_map`
- `digital_checkin`
- `digital_checkout`
- `multilingual_chat`
- `smart_notifications`
- `service_reviews`
- `faq`
- `help_center`
- `laundry`
- `kids_club`
- `pools`
- `gym`
- `transport`
- `parking`
- `statements`

## Runtime Truth Rules

The following rules are part of the pilot freeze:

- guest app pilot validation must happen in API mode, not asset mode
- asset mode is non-pilot fallback only
- template-only demo screens do not count as delivered pilot functionality
- mock loyalty/wallet screens do not count as delivered pilot functionality
- any module claim must be backed by a real active runtime path, not only by catalog presence

## Allowed Pilot Narrative

Safe statements for pilot-facing usage:

- Sevvn already supports a modular guest experience platform for hotels
- the pilot includes operational portal flows, guest app access, messaging, room service, restaurant journeys, and configurable hotel services
- some additional capabilities are already being built and can remain visible as roadmap, not as finished delivery

Unsafe statements for pilot-facing usage:

- every listed module is already live
- Sevvn already offers a complete launched partner network
- Sevvn already provides full wallet/loyalty/payment coverage across all journeys
- all templates are fully validated across every surface

## Operational Consequences

This scope freeze means:

- engineering should harden the included flows first
- the site and product copy should not overstate excluded flows
- sales/partnership conversations should use roadmap language for excluded items
- future feature work should be evaluated against this freeze before being pulled into the pilot month

## Next Step

With the scope now frozen, the next implementation step should move into hardening:

- rate limiting
- correlation IDs and structured logging
- public payload reduction
- admin audit trail
