# Module Readiness Matrix

Last updated: 2026-07-27

Legend:

- `Nao iniciado`
- `Somente UI`
- `Parcial`
- `Funcional`
- `Pronto para piloto`
- `Pronto para producao`

Interpretation rules used in this matrix:

- `Catalogo` means present in module catalog.
- `Registry` means platform-level registration/config schema exists.
- `Banco` means a real persistence path exists.
- `API` means there is a backend endpoint path that supports module behavior.
- `Portal` means hotel portal has a real operational/configuration surface.
- `Sevvn Admin` means global admin can meaningfully control or observe it.
- `App` means guest app has real reachable user flow.
- `5 templates` means the same module behavior is known to work across all five templates, not merely compile.
- `Testes` means meaningful automated test coverage exists somewhere in the relevant stack.
- `Dados reais` means module can run against persisted backend data rather than demo-only data.

Task 8 validation reference:

- see [pilot-module-validation-2026-07-27.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/pilot-module-validation-2026-07-27.md:1) for the module-by-module evidence pass completed on July 27, 2026

| Modulo | Catalogo | Registry | Banco | API | Portal | Sevvn Admin | App | 5 templates | Testes | Dados reais | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| home | Sim | Parcial | N/A | Parcial | N/A | N/A | Sim | Parcial | Parcial | Sim | Parcial |
| hotel_info | Sim | Nao | Parcial | Sim | Parcial | Nao | Sim | Parcial | Parcial | Sim | Funcional |
| services | Sim | Parcial | Sim | Sim | Sim | Parcial | Sim | Parcial | Parcial | Parcial | Parcial |
| bookings | Sim | Nao | Sim | Sim | Parcial | Nao | Sim | Parcial | Parcial | Sim | Parcial |
| messages | Sim | Nao | Sim | Sim | Sim | Nao | Sim | Parcial | Sim | Sim | Funcional |
| profile | Sim | Nao | Parcial | Parcial | N/A | N/A | Sim | Parcial | Parcial | Parcial | Parcial |
| basic_notifications | Sim | Nao | Sim | Sim | Parcial | Nao | Sim | Parcial | Parcial | Sim | Parcial |
| room_service | Sim | Sim | Sim | Sim | Sim | Parcial | Sim | Parcial | Sim | Sim | Pronto para piloto |
| restaurant | Sim | Sim | Sim | Sim | Sim | Parcial | Sim | Parcial | Sim | Sim | Pronto para piloto |
| spa | Sim | Sim | Sim | Sim | Sim | Parcial | Sim | Parcial | Parcial | Sim | Funcional |
| tours | Sim | Sim | Sim | Sim | Sim | Parcial | Sim | Parcial | Parcial | Sim | Funcional |
| events | Sim | Sim | Parcial | Parcial | Parcial | Nao | Parcial | Nao | Parcial | Parcial | Parcial |
| concierge | Sim | Nao | Nao | Nao | Nao | Nao | Parcial | Nao | Nao | Nao | Somente UI |
| laundry | Sim | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| kids_club | Sim | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| pools | Sim | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| gym | Sim | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| transport | Sim | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| parking | Sim | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| digital_wallet | Sim | Sim | Parcial | Parcial | Nao | Nao | Parcial | Nao | Parcial | Nao | Somente UI |
| payments | Sim | Nao | Sim | Sim | Parcial | Parcial | Parcial | Nao | Sim | Sim | Parcial |
| statements | Sim | Nao | Parcial | Parcial | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| promotions | Sim | Sim | Sim | Sim | Parcial | Parcial | Sim | Parcial | Sim | Sim | Funcional |
| loyalty | Sim | Sim | Nao | Nao | Nao | Nao | Parcial | Nao | Nao | Nao | Somente UI |
| interactive_map | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| service_reviews | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| digital_checkin | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| digital_checkout | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| smart_notifications | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| multilingual_chat | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| faq | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |
| help_center | Sim | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao | Nao iniciado |

## Notes By Module Family

### Core

- `home` exists in all templates but is not yet a fully backend-driven presentation layer.
- `bookings` currently bundles orders, table reservations, and stay bill concepts, so it is not yet a clean Sevvn-style reservation domain.
- `messages` is one of the strongest P0 modules today.

### Hospitality

- `room_service` and `restaurant` are the most pilot-ready hospitality modules.
- `spa` and `tours` can work through the generic service model but still need stricter platform validation and template compatibility verification.
- `events` is structurally possible via the generic service stack but is not treated as a ready module in the catalog.

### Finance / Experience

- `digital_wallet` and `loyalty` are the clearest examples where catalog status overstates production readiness.
- `payments` exists as backend/payment flow, but not yet as a coherent module abstraction.

## Recommended P0 Interpretation

P0 modules that can realistically be brought to pilot readiness with this codebase:

- `home`
- `hotel_info`
- `services`
- `bookings`
- `messages`
- `profile`
- `basic_notifications`
- `room_service`
- `restaurant`
- `spa`
- `tours`

Official pilot freeze for July 26, 2026:

- included directly: `hotel_info`, `messages`, `room_service`, `restaurant`
- included with hardening/validation: `home`, `services`, `bookings`, `profile`, `basic_notifications`, `spa`, `tours`, `promotions`
- keep outside the official pilot narrative: `events`, `payments`, `digital_wallet`, `loyalty`, and every unstarted catalog module

P1 modules that should stay behind flags or disabled:

- `events`
- `digital_wallet`
- `payments`
- `promotions`
- `loyalty`

P2/out of month:

- all remaining unstarted catalog modules
