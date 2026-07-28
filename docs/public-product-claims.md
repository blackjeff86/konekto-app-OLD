# Public Product Claims

Last updated: 2026-07-27

## Classification Legend

- `comprovada no produto`
- `demonstrável em ambiente de teste`
- `escopo de piloto controlado`
- `em desenvolvimento`
- `planejada`
- `não suportada`

## Core Platform Claims

| Public claim | Classification | Evidence / note |
|---|---|---|
| Sevvn é uma Guest Experience Platform modular | comprovada no produto | Backend, portal, admin, templates, plan presets and modules catalog exist |
| O aplicativo do hóspede é apenas uma das interfaces da plataforma | comprovada no produto | Guest app, hotel portal and platform admin all exist |
| Existe um portal operacional para o hotel | comprovada no produto | `apps/konekto_portal_next` |
| Existe uma administração central da plataforma | comprovada no produto | `apps/konekto_admin` + platform admin API routes |
| A plataforma suporta múltiplos hotéis com marca própria | comprovada no produto | Multi-tenant backend and per-hotel config/template/modeling |
| Novos módulos podem ser ativados sem reconstruir a base da plataforma | demonstrável em ambiente de teste | Module catalog + plan presets + hotel config toggles exist |

## Guest Journey Claims

| Public claim | Classification | Evidence / note |
|---|---|---|
| O hóspede pode acessar informações da hospedagem e Wi‑Fi | comprovada no produto | `hotel_info` module + guest claim/stay data |
| O hóspede pode fazer pedidos de Room Service | comprovada no produto | Orders + room service module |
| O hóspede pode reservar mesas / usar fluxos de restaurante | comprovada no produto | Restaurant service + table availability |
| O hóspede pode acessar passeios e serviços configurados pelo hotel | escopo de piloto controlado | Validated on July 27, 2026 through the real service model, but should still be presented as controlled pilot capability rather than broad finished coverage |
| O hóspede pode conversar com a equipe do hotel | comprovada no produto | guest/stay message flows exist |
| O hóspede recebe avisos e notificações básicas | comprovada no produto | notices + unread counters |
| Check-in digital | em desenvolvimento | exists in roadmap/catalog only |
| Check-out digital | em desenvolvimento | exists in roadmap/catalog only |
| Mapa interativo | em desenvolvimento | catalog exists, not public-ready |
| Chat multilíngue | planejada | catalog exists, not implemented |

## Hotel Operations Claims

| Public claim | Classification | Evidence / note |
|---|---|---|
| O hotel pode configurar módulos e aparência | comprovada no produto | settings/modules + settings/appearance |
| O hotel pode operar pedidos, hóspedes, estadias e quartos | comprovada no produto | portal + backend routes |
| O hotel pode gerenciar serviços e conteúdos | comprovada no produto | services/content/config routes |
| O hotel pode acompanhar integrações com sistemas | comprovada no produto | integrations settings + backend integration model |
| O hotel pode gerenciar equipe e acessos | comprovada no produto | staff management routes |

## Commercial / Revenue Claims

| Public claim | Classification | Evidence / note |
|---|---|---|
| A plataforma ajuda a organizar serviços e gerar novas oportunidades de receita | escopo de piloto controlado | services/orders/coupons support the claim inside the current pilot perimeter |
| Promoções e benefícios podem fazer parte da jornada | escopo de piloto controlado | Validated on July 27, 2026 for controlled pilot use through promotions + coupons, but still not a blanket mature revenue suite claim |
| Programa de fidelidade | em desenvolvimento | module exists but maturity is partial and outside the official pilot scope |
| Carteira da hospedagem | em desenvolvimento | digital wallet exists only as partial/demo-oriented capability and is outside the official pilot scope |
| Pagamento completo pelo app para todos os fluxos | não suportada | payment domain exists, but not as a complete finished public module |

## Integration Claims

| Public claim | Classification | Evidence / note |
|---|---|---|
| Sevvn integra com PMS e sistemas hoteleiros | escopo de piloto controlado | inbound/outbound integration routes and auth exist, but connector maturity should be presented carefully |
| Sevvn já possui conectores homologados com os principais PMS do mercado | não suportada | no repo evidence for vendor-certified integrations |
| A plataforma opera com webhooks e sincronização de dados operacionais | comprovada no produto | hotel integration, webhook and sync routes exist |

## Network / Partner Claims

| Public claim | Classification | Evidence / note |
|---|---|---|
| A Sevvn está construindo uma rede de parceiros e experiências | em desenvolvimento | partner models and routes exist, network narrative is future-facing |
| Parceiros locais poderão aparecer na jornada do hóspede | em desenvolvimento | partner-linked service items support this direction |
| A Rede Sevvn já está totalmente lançada | não suportada | no full network product exists today |
| Existe portal dedicado do parceiro | não suportada | not found in repo |

## Templates / Plans Claims

| Public claim | Classification | Evidence / note |
|---|---|---|
| Existem 5 templates visuais da mesma plataforma | comprovada no produto | `Aura`, `Bosque`, `Elite`, `Pulse`, `Horizon` |
| Os 5 templates preservam os fluxos centrais do piloto | comprovada no produto | Validated on July 27, 2026 for the shared pilot-safe guest flows after Home |
| Templates definem identidade visual e não a lógica da plataforma | comprovada no produto | Runtime validation on July 27, 2026 confirmed that the core pilot flows stay shared after Home even when the visual identity changes |
| Essential libera Aura e Bosque | comprovada no produto | `plan-presets.ts` |
| Premium libera os 5 templates | comprovada no produto | `plan-presets.ts` |
| Enterprise pode operar catálogo completo e customizações dedicadas | demonstrável em ambiente de teste | preset gets all modules; dedicated delivery is commercial/operational |

## Official Pilot Freeze Reference

For the current 30-day pilot phase, use [pilot-scope-freeze.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/pilot-scope-freeze.md) as the source of truth for what is:

- officially inside the pilot
- allowed only in controlled pilot language
- outside the pilot narrative

Supporting validation updates completed on July 27, 2026:

- [pilot-module-validation-2026-07-27.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/pilot-module-validation-2026-07-27.md:1)
- [template-compatibility-validation-2026-07-27.md](/abs/path/C:/ProjetosFlutter/konekto_app/docs/template-compatibility-validation-2026-07-27.md:1)
