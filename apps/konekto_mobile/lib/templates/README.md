# Templates White Label do app do hóspede

Os 5 templates válidos: **Aura**, **Bosque**, **Elite**, **Pulse**, **Horizon**. Cada
hotel escolhe um via `Hotel.config.template`, restrito pelo Plan Preset do hotel — ver
`apps/konekto_api/lib/plan-presets.ts`, a fonte de verdade de quais templates cada
preset permite (Essential: Aura/Bosque; Premium/Enterprise: todos).

**Desde a arquitetura de Módulos** (ver `tasks/plan.md`), template é só identidade
visual — nenhuma regra de negócio, nenhuma feature presa a um template específico.
O que o hóspede PODE fazer é resolvido por `lib/modules/` (Module Engine); o template
só decide COMO isso aparece. Só a **Home** ainda muda de conteúdo por template hoje
(a conversão pra Module Renderer puro, consumindo `lib/layout/` inteiro, é trabalho
futuro — ver nota no fim deste arquivo). As outras telas (Serviços, Reservas, Perfil,
Avisos, Meus Pedidos, Info do Hotel, Conta da estadia) usam um tema único e fixo
(`GuestAppTheme`, em `lib/theme/guest_app_theme.dart`) — nunca são exclusivas de
nenhum template.

## Estrutura

```
lib/templates/
  guest_template_registry.dart   — GuestTemplateId + tema/Home de cada um
  shared/                        — widgets/tema reaproveitados pelos 5
  <nome>/
    theme.dart                   — GuestTemplateTheme (paleta/tipografia)
    home_screen.dart             — Home, com dado real (GuestTemplateContentParams)
    splash_screen.dart           — dado de demonstração, sem rota ligada ainda
    onboarding_screen.dart       — idem
    room_service_screen.dart     — idem
    concierge_chat_screen.dart   — idem
    services_directory_screen.dart (ou experiences_directory, no Horizon) — idem

lib/modules/                     — Module Catalog (client) + Module Engine + Module
                                    Registry — ver lib/modules/README.md (a criar)
  screens/
    loyalty/<template>_loyalty_screen.dart   — só Elite/Pulse/Horizon têm tela
    wallet/<template>_wallet_screen.dart      — hoje (ver loyalty_wallet_dispatch.dart)
    loyalty_wallet_dispatch.dart              — resolve a tela certa por template,
                                                 `null` pra Aura/Bosque (sem tela ainda)

lib/layout/                      — Layout Registry + Home Layout Engine (arranjo
                                    visual dos módulos na Home — ver Fase 8/9)
lib/navigation/                  — Navigation Engine (como abrir a tela de um módulo)
lib/theme/theme_engine.dart      — overlays (dark mode/sazonal/marca) sobre o tema
                                    base de cada template
```

## Adicionar um 6º template

1. **Backend** (`apps/konekto_api/lib/plan-presets.ts`): acrescentar o id em
   `templateIds` do(s) preset(s) que vão poder escolhê-lo.
2. **Portal** (`apps/konekto_portal_next/app/(portal)/settings/appearance/page.tsx`):
   acrescentar uma entrada em `TEMPLATE_OPTIONS` — nome, tagline, descrição, cor de
   destaque, print real em `public/appearance/<id>-home.png`.
3. **Aqui**: criar `lib/templates/<id>/theme.dart` + `home_screen.dart` no mínimo (as
   outras telas são opcionais, com dado de demonstração até serem ligadas a dado
   real).
4. **Aqui**: registrar em `guest_template_registry.dart` — `GuestTemplateId`,
   `guestTemplateThemes`, `_homeContentBuilders`. Se o template quiser um arranjo de
   Home próprio (ver `lib/layout/home_layout_strategy.dart`), registrar em
   `lib/layout/home_layout_engine.dart` também.

## Adicionar um módulo novo

Não mexe em nada aqui — ver `apps/konekto_api/lib/module-catalog.ts` (Catalog) e
`lib/modules/module_registry.dart` (Registry, lado Flutter). Nenhum template precisa
mudar pra suportar um módulo novo.

## Loyalty/Carteira (Elite/Pulse/Horizon)

Hoje só esses 3 templates têm tela própria de Loyalty/Wallet (adaptadas dos mockups
Stitch de cada um) — Aura/Bosque ainda não têm um design equivalente, então
`resolveLoyaltyScreen`/`resolveWalletScreen` (`lib/modules/screens/loyalty_wallet_dispatch.dart`)
devolvem `null` pra eles, e a linha correspondente simplesmente não aparece no Perfil.
Dado (pontos/saldo) continua mock — sem modelo de backend pra isso ainda.

## Templates antigos

Os 5 templates de antes do White Label (Amara Bay/Verde Pousada/Casa Marechal/
Konekto Clássico/Konekto Noturno) foram arquivados em `../legacy-templates/` — fora
de `lib/`, não compilam, preservados só pra referência.

## Nota: Home ainda não é Module Renderer puro

A arquitetura de Módulos (Plan Preset → Module Catalog → Module Registry →
Configuração do Hotel → Module Engine → Home Layout Engine → Navigation Engine →
Theme Engine → Presentation Engine) está pronta e testada de ponta a ponta (ver
`tasks/plan.md`), mas os 5 `home_screen.dart` **continuam hand-authored** por decisão
explícita — convertê-los pra renderizar módulos genéricos regrediria visualmente as
Homes reais hoje (o Layout Registry só tem um card de fallback genérico, sem
variantes desenhadas por módulo/template ainda). Converter isso é trabalho futuro,
que exige desenho de verdade por módulo antes de tocar em `home_screen.dart`.
