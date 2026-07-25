# Templates White Label do app do hóspede

Os 5 templates válidos: **Aura**, **Bosque**, **Elite**, **Pulse**, **Horizon**. Cada
hotel escolhe um via `Hotel.config.template`, restrito pelo plano comercial
(Essential/Premium/Enterprise) — ver `apps/konekto_api/lib/feature-flags.ts`, a fonte
de verdade do catálogo.

Só a **Home** muda de visual por template. As outras telas (Serviços, Reservas,
Perfil, Avisos, Meus Pedidos, Info do Hotel, Conta da estadia) usam um tema único e
fixo (`GuestAppTheme`, em `lib/theme/guest_app_theme.dart`) — nunca são exclusivas de
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
    loyalty_screen.dart          — só Elite/Pulse/Horizon, atrás de GuestFeatureGate
    wallet_screen.dart           — idem
```

## Adicionar um 6º template

1. **Backend** (`apps/konekto_api/lib/feature-flags.ts`): acrescentar o id em
   `PREMIUM_TEMPLATES` (e em `ESSENTIAL_TEMPLATES` também, se o plano Essential
   também puder escolhê-lo).
2. **Portal** (`apps/konekto_portal_next/app/(portal)/settings/appearance/page.tsx`):
   acrescentar uma entrada em `TEMPLATE_OPTIONS` — nome, tagline, descrição, cor de
   destaque, print real em `public/appearance/<id>-home.png`.
3. **Aqui**: criar `lib/templates/<id>/theme.dart` + `home_screen.dart` no mínimo (as
   outras telas são opcionais, com dado de demonstração até serem ligadas a dado
   real — ver Task 9/10 do histórico em `tasks/todo-guest-app-whitelabel.md`).
4. **Aqui**: registrar em `guest_template_registry.dart` — `GuestTemplateId`,
   `guestTemplateThemes`, `_homeContentBuilders`.

## Adicionar uma 10ª feature flag

Não mexe em nada aqui — só em `apps/konekto_api/lib/feature-flags.ts`
(`FEATURE_FLAGS`) e em `apps/konekto_admin` (`_kFeatureFlags` em
`client_detail_page.dart`, pra equipe Konekto conseguir liberar de cortesia). Se a
flag precisar de tela no app do hóspede, o padrão é `GuestFeatureGate`
(`lib/templates/shared/widgets/guest_feature_gate.dart`) — ver `loyalty_screen.dart`/
`wallet_screen.dart` de Elite/Pulse/Horizon como exemplo.

## Templates antigos

Os 5 templates de antes do White Label (Amara Bay/Verde Pousada/Casa Marechal/
Konekto Clássico/Konekto Noturno) foram arquivados em `../legacy-templates/` — fora
de `lib/`, não compilam, preservados só pra referência.
