# Plano: Refatoração White Label do app do hóspede (konekto_mobile)

## Overview

Substituir os 5 templates visuais atuais do app do hóspede (Amara Bay, Verde Pousada,
Casa Marechal, Konekto Clássico, Konekto Noturno — todos construídos nesta mesma sessão,
a partir de dois exports anteriores do Stitch) pelos 5 novos templates de um terceiro
export do Stitch (`stitch_hospitality_tech_white_label_design.zip`): **Aura**, **Bosque**,
**Elite** (pasta do zip chama `lite`, renomeando por decisão do usuário), **Pulse** e
**Horizon**. Junto com a troca de templates, introduzir um sistema de **planos comerciais**
(Essential / Premium / Enterprise) e **feature flags** que controla tanto qual template um
hotel pode escolher quanto quais módulos do app (check-in digital, mapa interativo,
fidelidade, carteira digital, chat multilíngue, avaliação de serviço, notificações
inteligentes) ficam disponíveis — com o plano funcionando como um conjunto *padrão* de
flags, não uma trava rígida (dá pra liberar uma feature isolada pra um hotel Essential sem
mudar de plano).

Os 5 templates atuais **não são apagados** — ficam arquivados como referência, no final
deste plano (Fase 4), não no início.

## Decisões de arquitetura

- **"Elite" (não "Lite")**: renomear em todo o código/nomes de arquivo; o zip do Stitch usa
  `lite_*`, mas o produto final usa `elite`.
- **Reaproveitar `HotelSubscription.planName`**: hoje é `String` livre (só exibido no
  financeiro do `konekto_admin`, sem nenhuma ligação com acesso/templates). Vira um enum
  Prisma controlado (`essential` | `premium` | `enterprise`) que passa a ser a fonte de
  verdade tanto pro financeiro quanto pro controle de acesso — não criar um segundo campo
  `Hotel.plan` separado e concorrente.
- **Feature flags como mecanismo primário** (pedido explícito do usuário): o plano define
  um *default set* de flags ativas; hotéis individuais podem ter flags extras habilitadas
  como cortesia sem mudar de plano. Isso implica `config.enabledFeatures: string[]` (união
  sempre, nunca subtração — não dá pra desabilitar uma flag que o plano já dá por padrão,
  o que mantém a regra "Premium/Enterprise sempre podem usar template Essential" simples:
  a lista de templates permitidos é sempre `templatesOfPlan(plan)`, nunca customizável pra
  baixo).
- **Tradução do vocabulário React → Flutter** (o pedido original usa "Hooks"/"Services",
  termos de React; a stack real do app do hóspede é Flutter/Dart):
  - `Templates/<categoria>/<nome>` → `lib/templates/<nome>/` (cada um com seu próprio
    `home_screen.dart`, `theme.dart` etc.), sem sub-pastas por categoria de plano (a
    categoria é metadado do template, não a localização física — evita ter que mover
    arquivos se um template mudar de categoria).
  - `Shared/Components` → `lib/templates/shared/widgets/` (o que já existe hoje em parte:
    `ExpandableCard`, `ImageCarousel`, etc. — ver Task 4 pra inventário exato).
  - `Shared/Hooks` → **não existe hook em Flutter**. Vira `lib/templates/shared/state/`
    com `ChangeNotifier`/`ValueNotifier` controllers, seguindo o padrão que o projeto já
    usa (`AuthRepository`, `LocaleController`) — não introduzir Riverpod/Bloc só por causa
    disso, seria uma segunda mudança de arquitetura em paralelo sem necessidade.
  - `Shared/Services` → `lib/data/` (já existe — os repositórios atuais).
  - `Theme` → generaliza `lib/theme/guest_infra.dart` (ver Task 3).
- **Sequenciamento corrigido em relação ao pedido original**: o usuário pediu pra arquivar
  os templates atuais *antes* de tudo. Isso quebraria o app em produção imediatamente
  (`tenant_home_page.dart` continua sendo o único código que renderiza a home real até que
  os 5 novos templates estejam implementados e testados). Arquivamento vira a **última**
  tarefa da Fase 4 (cutover), não a primeira — os 5 templates atuais continuam ativos e no
  ar durante todo o desenvolvimento dos novos, exatamente como os antigos ficaram no ar
  durante a criação dos 5 atuais nesta sessão.
- **Sem `DESIGN.md` neste export**: paleta/tipografia de cada template extraídas
  diretamente do `tailwind.config` de cada `code.html` (mesma técnica já usada quando um
  export anterior não tinha o arquivo de identidade separado).
- **Horizon** (Task 11): a suposição inicial era de que só tinha splash screen no export —
  incorreta. O zip tem 8 telas reais pra ele. Por decisão do usuário, foi promovido a 5º
  template real desde a Fase 3 (não ficou "em breve"), no mesmo catálogo Premium/Enterprise
  de Elite/Pulse.

## Modelo de dados (Prisma)

```prisma
enum HotelPlan {
  essential
  premium
  enterprise
}

model HotelSubscription {
  hotelId       String      @id
  plan          HotelPlan   @default(essential)   // novo — substitui o uso informal de planName pra isso
  planName      String                             // mantém: rótulo comercial livre pro financeiro
  monthlyAmount Float?
  status        SubscriptionStatus @default(trial)
  paymentStatus SubscriptionPaymentStatus @default(em_dia)
  notes         String?
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
  hotel         Hotel       @relation(fields: [hotelId], references: [id])
}
```

`Hotel.config` (JSON já existente) ganha duas chaves novas, ao lado de `infra`:
- `template: string` — id do template escolhido (`aura` | `bosque` | `elite` | `pulse` | `horizon`)
- `enabledFeatures: string[]` — flags extras habilitadas além do default do plano.

## Task List

### Fase 1 — Fundação de dados e regras (backend)

- [ ] **Task 1**: Migration Prisma — enum `HotelPlan`, campo `HotelSubscription.plan`,
  script de backfill classificando hotéis existentes (default `essential`).
  - Verificação: `npx prisma migrate dev`; testes existentes de `HotelSubscription` continuam passando.
  - Escopo: S.
- [ ] **Task 2**: `lib/feature-flags.ts` no `konekto_api` — catálogo das 9 flags
  (`digital_checkin`, `digital_checkout`, `interactive_map`, `promotions`, `loyalty`,
  `digital_wallet`, `multilingual_chat`, `service_reviews`, `smart_notifications`),
  `defaultFeaturesByPlan: Record<HotelPlan, string[]>`, `resolveEnabledFeatures(hotel)`
  (união do default do plano + extras).
  - Verificação: teste cobrindo os 3 planos + o caso de cortesia.
  - Escopo: S.
- [ ] **Task 3**: `PATCH /api/hotels/{hotelId}` ganha `template`/`enabledFeatures` no
  schema Zod (ao lado de `infra`, que continua existindo até a Fase 4); `platform-admin`
  ganha campo pra setar `plan` na criação/edição de hotel.
  - Verificação: testes de contrato dos dois endpoints.
  - Escopo: M.

### Checkpoint A
- [ ] Migration aplicada sem quebrar dado existente.
- [ ] `resolveEnabledFeatures` testado pros 3 planos + cortesia.
- [ ] Revisar com o usuário antes de tocar no Flutter.

### Fase 2 — Arquitetura de templates no Flutter (sem trocar o visual ainda)

- [ ] **Task 4**: Inventariar `lib/app/tenants/` e `lib/theme/` — separar o compartilhável
  (repositórios, navegação, formatação) do específico de template (cores/tipografia/layout
  da home). Documentar no topo do novo `lib/templates/shared/`.
  - Escopo: S.
- [ ] **Task 5**: Criar `lib/templates/` com `shared/{widgets,state}/` e um
  `template_registry.dart` (`templateId → TemplateDefinition`) — inicialmente só
  reexportando os 5 templates atuais, sem mudar nenhum pixel. Prova de que a arquitetura
  nova funciona antes de migrar conteúdo novo pra dentro dela.
  - Verificação: `flutter analyze` limpo, app roda idêntico ao de hoje.
  - Escopo: M.
- [ ] **Task 6**: Client de feature flags no Flutter — `GuestFeatures` resolvido do
  `tenantConfig`, `GuestFeatures.has('digital_checkin')`; widgets condicionais usam isso,
  nunca checam `plan` diretamente.
  - Verificação: teste unitário do parser + fallback seguro (flag desconhecida = desligada).
  - Escopo: S.

### Checkpoint B
- [ ] App roda idêntico ao de hoje (zero regressão visual) sobre a arquitetura nova.
- [ ] Revisar com o usuário antes de migrar os templates novos.

### Fase 3 — Migração dos 5 novos templates

- [ ] **Task 7**: Extrair paleta/tipografia de cada `code.html` (Aura, Bosque, Elite,
  Pulse) e criar os 4 `TemplateDefinition` (cores/fontes só — reaproveita os widgets de
  `shared/`, sem duplicar layout por template).
  - Escopo: M.
- [ ] **Task 8**: Migrar a tela **Home** dos 4 templates reais — a mais crítica.
  - Verificação: comparação visual manual com o `screen.png` de cada um.
  - Escopo: L — dividir em 4 sub-tasks (1 por template) se surgirem diferenças estruturais grandes.
- [ ] **Task 9**: Migrar as telas comuns aos 4 (Room Service, Concierge Chat, Onboarding,
  Splash, Diretório de Serviços).
  - Escopo: L, dividir por tela se necessário.
- [ ] **Task 10**: Telas exclusivas de plano nos templates que as têm no zip (Elite/Pulse
  têm `loyalty_program`/`wallet_charges`) — atrás das feature flags `loyalty`/
  `digital_wallet` da Fase 1, não como parte fixa do template.
  - Escopo: M.
- [ ] **Task 11**: Horizon — como só tem 1 tela no export, implementar como entrada
  "em breve/desabilitada" no seletor, não como template completo fingido.
  - Escopo: S.

### Checkpoint C — gate obrigatório
- [ ] Os 4 templates reais comparados tela a tela com os `screen.png` do Stitch.
- [ ] `flutter analyze` e suite de testes limpos.
- [ ] QA manual: trocar de template muda tudo (cor/fonte/layout) sem quebrar nenhuma tela.
- [ ] Revisar com o usuário antes do cutover.

### Fase 4 — Seletor de template/plano no portal + cutover

- [ ] **Task 12**: `/settings/appearance` do `konekto_portal_next` lista os 5 templates
  novos, **restrita pelos templates permitidos no plano do hotel** (Essential só vê 2 dos
  4 — ver Open Questions). Reaproveita o mockup de iPhone já construído nesta sessão, só
  troca a fonte das imagens.
  - Escopo: M.
- [ ] **Task 13**: Tela de gestão de plano/features no `konekto_admin` (equipe Konekto
  define plano na criação/edição; toggle individual de feature como cortesia).
  - Escopo: M.
- [ ] **Task 14**: Cutover — trocar `infra` legado por `template` como campo ativo em
  produção (migração de dado: mapear os hotéis/templates atuais pro template novo — ver
  Open Questions). **Só aqui** arquivar os 5 templates atuais: mover as partes
  específicas de template de `tenant_home_page.dart`, `guest_infra.dart` (versão com os 5
  tokens atuais) e telas relacionadas pra `apps/konekto_mobile/legacy-templates/`,
  preservando estrutura, fora de `lib/` (não compilado, só referência).
  - Escopo: L — considerar quebrar em 2-3 tasks (migração de dado / troca de rota+registry / arquivamento).

### Checkpoint D — gate obrigatório
- [ ] Nenhum hotel real fica sem template válido depois da migração de dado.
- [ ] Templates antigos arquivados, não apagados — `git log` preserva histórico.
- [ ] Deploy de produção (API + guest app + portal) verificado ponta a ponta.

### Fase 5 — Limpeza e preparação pra Enterprise

- [ ] **Task 15**: Remover o campo `infra` do schema (após confirmar que nenhum hotel
  ainda depende dele) e as referências restantes no admin/portal/mobile.
- [ ] **Task 16**: Documentar (CLAUDE.md do `konekto_mobile` e do `konekto_api`) a
  convenção pra adicionar um 6º template ou uma 10ª feature flag no futuro.

## Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Arquivar os templates atuais cedo demais quebra o app em produção | Alto | Sequenciamento corrigido — arquivamento só na Fase 4, depois do cutover |
| `enabledFeatures` livre demais permite estado inconsistente (feature ligada sem o template que a usa) | Médio | Toda checagem de feature no Flutter é sempre por flag, nunca por `plan`; UI de features no admin só mostra toggles relevantes ao template ativo |
| 4 templates reais migrados sem padronizar estrutura ⇒ duplicação | Alto | Task 5 (registry) e regra explícita "shared/ primeiro, tema depois" antes de migrar qualquer template |
| Nome "Lite" vazando em algum lugar do código em vez de "Elite" | Baixo | Grep de auditoria (`lite`) como último passo da Fase 3 |
| ~~Horizon sem telas reais~~ | — | Resolvido na Task 11: o zip tinha 8 telas reais, promovido a template completo |

## Decisões (confirmadas com o usuário)

- **Templates do plano Essential**: Aura e Bosque. Premium/Enterprise têm acesso a todos
  os 4 reais (Aura/Bosque/Elite/Pulse) + Horizon quando ele deixar de ser placeholder.
- **Mapeamento de template no cutover (Task 14)**: manual, por hotel — cada hotel
  existente (incluindo `hotel_1`/`hotel_2`) recebe uma escolha explícita, não um default
  automático. Decidir a escolha de cada hotel é parte da Task 14, não fica implícito.
- **Toggle de cortesia de feature**: só a equipe Konekto vê/mexe (via `konekto_admin`,
  Task 13) — não fica exposto pro hotel no `konekto_portal_next`.
