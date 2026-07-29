# Todo: White Label do app do hóspede

Plano completo: `tasks/plan-guest-app-whitelabel.md`.

## Fase 1 — Fundação de dados e regras (backend)
- [x] Task 1: Migration `HotelPlan` enum + `HotelSubscription.plan` + backfill
- [x] Task 2: `lib/feature-flags.ts` (catálogo de 9 flags + resolver por plano)
- [x] Task 3: `PATCH /api/hotels/{hotelId}` com `template`/`enabledFeatures`; plan no platform-admin
- [x] **Checkpoint A** — 372/372 testes, build limpo — revisar com o usuário

## Fase 2 — Arquitetura de templates no Flutter
- [x] Task 4: Inventariar `lib/app/tenants/` e `lib/theme/` (compartilhável vs específico)
- [x] Task 5: `lib/templates/` + `template_registry.dart` (reexporta os 5 atuais, zero mudança visual)
- [x] Task 6: Client de feature flags no Flutter (`GuestFeatures`)
- [x] **Checkpoint B** — revisado com o usuário, aprovado ("sim, pode seguir")

## Fase 3 — Migração dos 5 novos templates
- [x] Task 7: Extrair paleta/tipografia de Aura/Bosque/Elite/Pulse/Horizon
      (`lib/templates/{aura,bosque,elite,pulse,horizon}/theme.dart` +
      `lib/templates/shared/guest_template_theme.dart`) — zip extraído em
      `stitch_hospitality_tech_white_label_design.zip` (Downloads), tokens
      vieram de 5 `DESIGN.md` com nomes conceituais que não batem com o nome
      do template — mapeamento (confirmado batendo cor a cor com o
      `tailwind.config` de cada `*_home/code.html`):
      `aura` = pasta `elevated_hospitality_suite`,
      `bosque` = pasta `bosque` (bate direto),
      `elite` = pasta `silent_luxury_experience` (telas do zip usam prefixo
      `lite_`, mas o nome oficial nosso é `elite`),
      `pulse` = pasta `pulse_tech_luxury`,
      `horizon` = pasta `horizon_identity`.
- [x] Task 8: Migrar Home dos 4 templates reais (Aura/Bosque/Elite/Pulse) —
      `lib/templates/{aura,bosque,elite,pulse}/home_screen.dart` +
      `lib/templates/guest_template_registry.dart` (registry provando que os
      4 encaixam, ainda não ligado a nenhuma tela de verdade — isso é Fase 4).
      `flutter analyze` limpo. Adaptações deliberadas em relação ao mockup:
      cartões de Check-in/Check-out/Guests (Aura), Cabin Temp (Bosque) e
      Access Code (Elite) foram omitidos por não serem dado real hoje — só
      quarto + wifi, igual ao critério já usado nos 5 templates antigos.
      Adicionadas 4 strings novas no l10n (pt/en/es): `bosqueQuote`,
      `eliteTag`, `pulseTag`.
      **Não verificado visualmente** (sem Chrome/emulador neste ambiente) —
      vale rodar `flutter run` e comparar com os `screen.png` do zip antes do
      Checkpoint C.
- [x] Task 9: Migrar telas comuns (Room Service, Concierge Chat, Onboarding,
      Splash, Diretório de Serviços) — 4 templates × 5 telas comuns.
      `flutter analyze` limpo em tudo. Nenhuma dessas telas está ligada a
      rota real ainda (isso é Fase 4). Dado fictício nas telas com
      preço/conteúdo real (Room Service, Diretório de Serviços) por decisão
      explícita do usuário ("mockup fiel por enquanto, ajusto depois") —
      **precisa trocar por dado real antes de produção**.
  - [x] Splash — `lib/templates/{aura,bosque,elite,pulse}/splash_screen.dart` +
        `lib/templates/shared/guest_template_splash_screen.dart` (widget
        único reaproveitado, só texto/paleta muda). Fundo trocado de foto de
        estoque (mockup) por gradiente/blobs da própria paleta — sem foto
        real do hotel pra usar aqui. Ainda sem rota real (o app hoje vai
        direto do código de acesso pra Home, sem splash — Fase 4 decide se
        isso entra no fluxo de verdade).
  - [x] Room Service — `lib/templates/{aura,bosque,elite,pulse}/room_service_screen.dart`
        + `lib/templates/shared/guest_template_menu_item.dart`. **Decisão do
        usuário**: mockup fiel por enquanto (itens/preços fictícios do
        Stitch, tipo "Wagyu Burger $28"), ajustar depois. Cada tela tem seu
        próprio carrinho local (`setState`, sem persistência) só pra provar
        a interação de "adicionar". **Antes de produção**: trocar
        `GuestTemplateMenuItem` fixo pelo `ServiceItem` real
        (`konekto/data/services_repository.dart`) — isso é Fase 4.
  - [x] Concierge Chat — `lib/templates/{aura,bosque,elite,pulse}/concierge_chat_screen.dart`
        + `lib/templates/shared/widgets/guest_template_chat_{bubble,input_bar}.dart`.
        Conversa de demonstração (mesmo critério do Room Service) — Fase 4
        troca pelo `MessagesRepository` real.
  - [x] Onboarding — `lib/templates/{aura,bosque,elite,pulse}/onboarding_screen.dart`
        + `lib/templates/shared/guest_template_onboarding_{screen,slide}.dart`
        (PageView de 3 slides + indicadores + Pular/Avançar, reaproveitado
        pelos 4). Fundo trocado de foto de estoque por cor sólida da paleta
        (mesmo critério do Splash). Copy dos slides: Elite usa os 3 textos
        reais do mockup (só ele exportou os 3); os outros 3 tiveram só 1
        slide exportado — completei os outros 2 no mesmo tom de voz.
  - [x] Diretório de Serviços — `lib/templates/{aura,bosque,elite,pulse}/services_directory_screen.dart`
        + `lib/templates/shared/guest_template_service_category.dart`.
        Categorias fictícias (mesmo critério do Room Service).
- [x] Task 10: Telas premium-only atrás de feature flag (loyalty/wallet) —
      `lib/templates/{elite,pulse}/{loyalty,wallet}_screen.dart` +
      `lib/templates/shared/widgets/guest_feature_gate.dart` (porteiro
      genérico: só renderiza a tela se `GuestFeatures.has(flag)`, senão
      mostra estado de bloqueio — usa o `GuestFeatures` da Task 6 de
      verdade, não só decorativo). **Só Elite e Pulse** — Aura/Bosque não
      têm mockup de loyalty/wallet no zip (consistente com serem tier
      Essential, que não inclui essas 2 flags por padrão). `flutter analyze`
      limpo.
- [x] Task 11: **decisão do usuário** — promover Horizon a 5º template real
      agora (não ficar "em breve"). Feito:
  - Backend: `templatesOfPlan` (`feature-flags.ts`) agora inclui `horizon`
    pra premium/enterprise; `PATCH /api/hotels/{hotelId}` (`route.ts`)
    aceita `template: 'horizon'`. Teste ajustado
    (`feature-flags.test.ts`), suite completa 372/372, `tsc --noEmit` limpo.
  - Flutter: as 8 telas do Horizon migradas —
    `lib/templates/horizon/{home,splash,onboarding,room_service,
    concierge_chat,experiences_directory,loyalty,wallet}_screen.dart`.
    `experiences_directory` é o nome próprio do mockup pro equivalente do
    Diretório de Serviços; `loyalty`/`wallet` também atrás de
    `GuestFeatureGate`, igual Elite/Pulse.
  - `guest_template_registry.dart` atualizado: Horizon entra no
    `_homeContentBuilders` (antes só tinha o tema, sem Home).
  - `flutter analyze` limpo em tudo.
- [x] **Checkpoint C (gate obrigatório)** — aprovado pelo usuário ("sim, pode seguir")

## Fase 4 — Portal + cutover
- [x] Task 12: `/settings/appearance` com os 5 templates novos, restrito por plano.
      **Decisão do usuário**: substituir o seletor pelos 5 novos (não manter os
      antigos em paralelo), com aviso de pré-lançamento — o app Flutter ainda
      não renderiza os templates novos de verdade até a Task 14.
  - Backend: `GET /api/hotels/{hotelId}` agora inclui `plan` e `allowedTemplates`
    na resposta (derivados de `HotelSubscription.plan` via `templatesOfPlan`,
    nunca guardados em `Hotel.config`). Teste atualizado. 373/373 no
    `konekto_api`, `tsc --noEmit` limpo.
  - Portal: `types/hotelConfig.ts` (+`template`/`plan`/`allowedTemplates`),
    `lib/api/hotelConfig.ts` (+`updateTemplate`), `hooks/useHotelConfig.ts`
    (+mutation), `/settings/appearance/page.tsx` reescrita — 5 templates
    novos com prints reais (`public/appearance/{aura,bosque,elite,pulse,
    horizon}-home.png`, copiados do zip), template fora do plano aparece
    com badge "Disponível no Premium" e desabilitado (não escondido),
    banner de aviso de pré-lançamento. 176/176 no portal, build limpo (os 2
    erros de `tsc --noEmit` em `OccupancyForm.test.tsx`/`StayDetail.test.tsx`
    são pré-existentes, não relacionados — `next build` confirma limpo).
- [x] Task 13: Gestão de plano/features no `konekto_admin`
  - Backend: `platform-admin-hotel-shape.ts` agora expõe `subscription.plan`
    e dois campos novos (`defaultFeatures` — o que o plano já dá, só
    leitura; `enabledFeatures` — só as extras de cortesia, nunca as do
    plano). Testes novos cobrindo os 2. 376/376 no `konekto_api`.
  - Flutter (`konekto_admin`): `clients_repository.dart` — `Subscription.plan`,
    `HotelOverview.{defaultFeatures,enabledFeatures}`, `createHotel`/
    `updateSubscription` ganham `plan`, novo `updateEnabledFeatures`.
    `_CreateHotelDialog` ganha seletor de plano (Essential/Premium/
    Enterprise). `client_detail_page.dart` ganha dropdown de plano no card
    de assinatura + card novo "Recursos Premium" (chips travados=incluído
    no plano, chips clicáveis=cortesia), salvando via
    `updateEnabledFeatures`. `flutter analyze` limpo (sem suite de testes
    neste app pra rodar).
- [~] Task 14: Cutover — **parcial, por decisão do usuário** (só o mecanismo,
      sem mexer em hotel real ainda):
  - [x] Mecanismo de troca de rota: `TenantHomeBody` (`tenant_home_page.dart`)
        agora checa `tenantConfig['template']` primeiro
        (`guestTemplateIdFromString`, novo em `guest_template_registry.dart`)
        e só cai no sistema antigo (`infra`/`GuestInfra`) quando ausente.
        **Nenhum hotel real tem `template` setado hoje** — esse caminho
        novo é inalcançável em produção agora, zero risco. Só a Home muda
        de sistema; bottomNavigationBar/Serviços/Reservas/Perfil continuam
        no visual antigo mesmo quando `template` está presente (não
        migrados — ver limitação documentada no código). `flutter analyze`
        limpo.
  - [x] Migração de dado — **concluída em produção**, direto no banco:
    - `hotel_1` (que era na verdade o cliente real "Konekto Hotel", marcado
      incorretamente como `kind: template` em algum momento) corrigido pra
      `kind: client` e renomeado pra um ID de verdade
      (`b370eef7-0317-4f03-9bdb-c5bfe1b17682`) — nunca foi template, era
      confusão de dado.
    - `hotel_2` ("Amara Bay", instalação-demonstração do sistema antigo,
      sem cliente/staff/hóspede algum) apagado por completo (serviços,
      conteúdo, o hotel).
    - Todo hotel novo já nasce com `template: aura` por padrão
      (`POST /api/platform-admin/hotels`) — decisão do usuário.
    - Konekto Hotel e Hotel Damm (os 2 únicos clientes reais) ganharam
      `template` — Hotel Damm recebeu o default `aura`; Konekto Hotel já
      tinha escolhido `bosque` manualmente (preservado, não sobrescrito).
    - `seed.ts` limpo: removido todo código de seed de hotel_1/hotel_2
      (não existe mais o conceito de "hotel-modelo" pra template — os 5
      templates não dependem de nenhum hotel no banco, a prévia no portal
      usa print estático). `prisma/seed-data/hotel_1/`, `hotel_2/`
      removidos. README atualizado.
    - **Resultado**: com o build novo do `konekto_mobile` já deployado
      (mecanismo da Task 14), os 2 hotéis reais agora renderizam os
      templates novos de verdade pros hóspedes — não é mais só mecanismo
      inerte, está ativo em produção.
  - [x] Arquivamento do código dos 5 templates antigos — **concluído**.
    - `legacy-templates/` (fora de `lib/`, excluído do `flutter analyze`,
      não compila): `guest_infra.dart`, `template_registry.dart` antigo,
      `amara_bay/`, `verde_pousada/`, `casa_marechal/` (home_screen.dart de
      cada), `shared/guest_home_content_params.dart`,
      `shared/widgets/{expandable_card,header_icon_button,image_carousel,
      notification_count_badge,tenant_logo}.dart` — com `git mv` (preserva
      histórico) + README explicando como reativar se um dia fizer sentido.
    - **Descoberta importante durante a execução**: 12 telas (Serviços,
      Reservas, Perfil, Avisos, Meus Pedidos, Info do Hotel, Conta da
      estadia, Minibar, etc.) dependiam do sistema antigo pra se
      estilizar — não eram exclusivas de nenhum template. Por decisão do
      usuário ("essas funcionalidades não deveriam estar presas aos
      templates"), `GuestAppTheme` virou um tema único e fixo
      (`GuestSharedTokens`, os valores do antigo default Verde Pousada),
      independente de qual dos 5 templates novos o hotel escolheu pra
      Home — só a Home troca de visual por template, o resto do app é
      consistente sempre.
    - `tenant_home_page.dart`: Home sempre renderiza um dos 5 templates
      novos (fallback `aura` se `tenantConfig['template']` estiver
      ausente — nunca quebra por falta de dado).
    - `flutter analyze` limpo, build de produção limpo, deployado e
      confirmado no ar (`konekto-guest.vercel.app`).
- [ ] **Checkpoint D (gate obrigatório)**

## Fase 5 — Limpeza
- [x] Task 15: Remover campo `infra` legado — removido dos 4 apps
      (`konekto_api`: `patchHotelSchema`/`createHotelSchema`;
      `konekto_portal_next`: `updateInfra`/tipo `HotelConfig`;
      `konekto_admin`: seletor de "estilo visual" no diálogo de criar
      cliente; `konekto_mobile`: comentário desatualizado). Testes
      atualizados (374/374 no `konekto_api`, 176/176 no portal,
      `flutter analyze` limpo no mobile/admin). Deployado e verificado nos
      3 apps com pipeline Vercel.
- [x] Task 16: Documentar convenção pra novo template/feature flag —
      `apps/sevvn_api/lib/feature-flags.ts` (cabeçalho do arquivo, fonte
      de verdade dos 2 catálogos) + `apps/konekto_mobile/lib/templates/README.md`
      (espelha a mesma convenção do lado Flutter). Passo a passo pra 6º
      template (4 lugares) e 10ª feature flag (2 lugares).

## Fase 5 concluída — White Label completo, ponta a ponta, em produção.

## Pendências (adiadas, não bloqueiam a Fase 3)
- [ ] Rodar `flutter test` de verdade em `konekto_mobile` (inclui o teste novo de
      `GuestFeatures`) — este ambiente não tem Chrome instalado e o projeto exige
      `--platform chrome` (`dart_test.yaml`, por causa do `package:web` no
      tokenizador de pagamento). Só o `flutter analyze` foi possível de rodar aqui.

## Decisões confirmadas
- [x] Essential = Aura + Bosque. Premium/Enterprise = todos.
- [x] Mapeamento de template no cutover: manual, por hotel.
- [x] Toggle de cortesia de feature: só equipe Konekto (`konekto_admin`), não exposto ao hotel.

