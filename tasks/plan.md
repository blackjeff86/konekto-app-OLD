# Implementation Plan: Portal do Hotel — Configurações (+ Convite de Staff)

Spec de referência: `specs/portal-fase5-hospedes-pedidos-config.md`. Este plano cobre só a **primeira sub-entrega** da Fase 5 (Configurações), que foi definida como a mais independente/menor risco. Hóspedes e Pedidos recebem seu próprio Plan depois que esta parte estiver completa e testada.

## Overview

Hoje o hotel só existe como dados estáticos: `hotels.config` (jsonb) tem branding/tema, e `hotel_content` (jsonb) tem cada página/catálogo (room service, spa, restaurantes, eventos, passeios). Tudo isso já é lido pelo app do hóspede via API, mas só pode ser escrito manualmente (Prisma Studio ou script de seed). Esta entrega dá ao `gerente` um jeito real de editar essa marca e esses catálogos pelo portal, item por item, e de convidar contas `recepcao` — sem precisar de um desenvolvedor.

## Architecture Decisions

- **PATCH genérico de conteúdo** (`PATCH /api/hotels/:hotelId/content/:docName`): recebe o objeto `data` completo já modificado (não um diff/patch parcial) e substitui o documento inteiro. Evita construir uma rota/schema Zod por tipo de catálogo (room service, spa, restaurantes, eventos, passeios têm formatos diferentes: `menu[].items[]` vs `spaServices[]` vs `restaurants[].menuItems[]`) — a validação estrutural fica no lado do Flutter (cada tela sabe o formato do seu próprio catálogo), a API só garante que é um JSON válido e que quem chama é `gerente` daquele hotel.
- **PATCH de branding** (`PATCH /api/hotels/:hotelId`): aceita um merge raso em `hotelInfo` (`name`, `logoUrl`) e `colorPalette` (`primary`, `secondary`) — não o objeto `config` inteiro, pra não arriscar apagar campos que a tela de branding não conhece (ex: `promoImages`).
- **Guarda de papel compartilhada** (`lib/auth-guard.ts`): função única que verifica o JWT e o `role`, reutilizada por toda rota que hoje é só leitura e vai virar leitura+escrita. Único lugar que decide "isso aqui é `gerente`-only".
- **Editor de catálogo, um de cada vez**: construir o editor de Room Service primeiro (estabelece o padrão: carregar doc → listar itens → formulário de item → salvar via PATCH genérico), depois repetir o padrão pros outros 4 — não abstrair um widget genérico antes de ter pelo menos 2 implementações reais pra saber o que de fato é comum (YAGNI).
- **Convite de staff**: novo model `StaffInvite` (`code` único, `hotelId`, `role` fixo em `recepcao` — um convite nunca cria outro `gerente`, reduz o raio de impacto de um convite vazado). Sem e-mail/verificação — o `gerente` compartilha o código por fora (WhatsApp, etc.), e quem recebe usa o código numa tela de cadastro simples.

## Task List

### Phase 1: Foundation

- [ ] **Task 1: Guarda de papel compartilhada (`requireStaffRole`)**
  - **Description:** Criar `apps/konekto_api/lib/auth-guard.ts` com uma função que extrai o Bearer token, verifica via `verifyStaffToken` (já existe em `lib/jwt.ts`), confirma que o `role` do payload está entre os papéis permitidos, e retorna o payload ou lança um erro tipado que as rotas convertem em `403`.
  - **Acceptance criteria:**
    - [ ] `requireStaffRole(request, ['gerente'])` retorna o payload quando o token é válido e o papel bate.
    - [ ] Retorna `401` (sem token/token inválido) ou `403` (papel não permitido) nos outros casos, sem vazar detalhe do erro JWT.
  - **Verification:** `curl` manual: chamar uma rota protegida sem token (`401`), com token de `recepcao` numa rota `gerente`-only (`403`), com token de `gerente` válido (`200`).
  - **Dependencies:** None.
  - **Files:** `apps/konekto_api/lib/auth-guard.ts` (novo).
  - **Estimated scope:** XS.

- [ ] **Task 2: `PATCH /api/hotels/:hotelId` (branding)**
  - **Description:** Adicionar o método `PATCH` na rota existente de leitura de hotel, aceitando `{ hotelInfo?: { name?, logoUrl? }, colorPalette?: { primary?, secondary? } }` via Zod, mesclando raso sobre o `config` atual (`{...current, hotelInfo: {...current.hotelInfo, ...body.hotelInfo}, ...}`), protegida por `requireStaffRole(['gerente'])` e checando que `payload.hotelId === params.hotelId` (gerente só edita o próprio hotel).
  - **Acceptance criteria:**
    - [ ] `PATCH` com `role: gerente` e `hotelId` correto atualiza só os campos enviados, preserva o resto do `config`.
    - [ ] `PATCH` com `role: recepcao` retorna `403`.
    - [ ] `PATCH` com `hotelId` de outro hotel retorna `403` (mesmo sendo `gerente`).
  - **Verification:** `curl -X PATCH` manual com os 3 casos acima; `GET` depois pra confirmar a mudança persistiu e o resto do `config` não mudou.
  - **Dependencies:** Task 1.
  - **Files:** `apps/konekto_api/app/api/hotels/[hotelId]/route.ts`.
  - **Estimated scope:** S.

- [ ] **Task 3: `PATCH /api/hotels/:hotelId/content/:docName` (catálogo genérico)**
  - **Description:** Adicionar `PATCH` na rota existente de leitura de conteúdo, recebendo `{ data: object }` via Zod (só valida que é um objeto, sem schema estrutural), substituindo o campo `data` do `HotelContent` correspondente. Mesma guarda `requireStaffRole(['gerente'])` + checagem de `hotelId`.
  - **Acceptance criteria:**
    - [ ] `PATCH` substitui o documento inteiro e retorna o novo `data`.
    - [ ] Mesmas regras de papel/hotel da Task 2.
  - **Verification:** `curl -X PATCH` alterando `roomService`, confirmar via `GET` que o app do hóspede (rodando com `USE_API=true`) reflete a mudança sem rebuild.
  - **Dependencies:** Task 1.
  - **Files:** `apps/konekto_api/app/api/hotels/[hotelId]/content/[docName]/route.ts`.
  - **Estimated scope:** S.

### Checkpoint: Foundation
- [ ] Tasks 1–3 com `curl` validando os 3 casos de autorização em cada rota.
- [ ] `npm run build` limpo em `apps/konekto_api`.
- [ ] Revisar com o usuário antes de seguir pro portal.

### Phase 2: Branding (fatia vertical completa)

- [ ] **Task 4: Repositório de branding no portal**
  - **Description:** `apps/konekto_portal/lib/data/hotel_config_repository.dart` — `Future<Map<String,dynamic>> getConfig(hotelId)` (reusa o mesmo endpoint de leitura já usado pelo dashboard) e `Future<void> updateBranding(hotelId, {name?, logoUrl?, primary?, secondary?})` (chama a Task 2).
  - **Acceptance criteria:** Repositório compila e tem teste unitário simples com `http.Client` fake confirmando o body enviado.
  - **Verification:** `flutter test`.
  - **Dependencies:** Task 2.
  - **Files:** `apps/konekto_portal/lib/data/hotel_config_repository.dart` (novo), `test/data/hotel_config_repository_test.dart` (novo).
  - **Estimated scope:** S.

- [ ] **Task 5: Tela de Configurações — aba Marca**
  - **Description:** Nova `apps/konekto_portal/lib/features/settings/settings_page.dart`, substituindo o `PlaceholderSectionCard` da seção Configurações no `DashboardPage`. Formulário com nome do hotel, URL do logo, cor primária/secundária (color picker simples ou campo hex), botão salvar chamando a Task 4. Some se `session.role != gerente` (mostra mensagem "só gerentes têm acesso" em vez do formulário).
  - **Acceptance criteria:**
    - [ ] Gerente vê o formulário pré-preenchido com os dados atuais do hotel.
    - [ ] Salvar chama o PATCH e mostra confirmação visual (snackbar/toast).
    - [ ] Recepção vê a mensagem de acesso negado, não o formulário.
  - **Verification:** `flutter analyze` + `flutter test`; manual: editar nome do hotel, recarregar o app do hóspede (`USE_API=true`), confirmar que o nome mudou na tela de acesso.
  - **Dependencies:** Task 4.
  - **Files:** `apps/konekto_portal/lib/features/settings/settings_page.dart` (novo), `apps/konekto_portal/lib/features/dashboard/dashboard_page.dart` (troca o placeholder pela tela nova quando `_selectedIndex` for Configurações).
  - **Estimated scope:** M.

### Checkpoint: Branding
- [ ] Fluxo ponta a ponta manual: editar no portal → ver refletido no app do hóspede.
- [ ] `flutter analyze`/`flutter test` limpos no portal.
- [ ] Revisar com o usuário antes de seguir pro catálogo.

### Phase 3: Catálogo — Room Service (estabelece o padrão)

- [ ] **Task 6: Repositório + modelo de catálogo (Room Service)**
  - **Description:** `apps/konekto_portal/lib/data/catalog_repository.dart` com `getRoomService(hotelId)` / `updateRoomService(hotelId, data)`, e um modelo `RoomServiceItem` (id, category, name, description, price, imageUrl, preparationTime) com `fromJson`/`toJson` batendo no formato real (`menu: [{category, items: [...]}]`, ver `prisma/seed-data/hotel_1/room_service_menu.json`).
  - **Acceptance criteria:** Parse e serialização ida-e-volta preservam o `pageConfig` (estilo) inalterado — só os itens são editáveis, o resto do doc passa direto.
  - **Verification:** teste unitário de round-trip (parse → toJson → compara com o original).
  - **Dependencies:** Task 3.
  - **Files:** `apps/konekto_portal/lib/data/catalog_repository.dart` (novo), `apps/konekto_portal/lib/models/room_service_item.dart` (novo), teste correspondente.
  - **Estimated scope:** M.

- [ ] **Task 7: Tela de edição de Room Service**
  - **Description:** Lista de itens agrupados por categoria, com editar/remover por item e "adicionar item" (formulário: nome, descrição, preço, URL da imagem, tempo de preparo). Salvar reserializa o doc inteiro e chama `updateRoomService`.
  - **Acceptance criteria:**
    - [ ] Adicionar, editar e remover item funcionam e persistem (confirmado via reload).
    - [ ] Categoria vazia (todos os itens removidos) não quebra a tela nem o app do hóspede.
  - **Verification:** `flutter analyze`/`flutter test`; manual: adicionar item no portal, abrir o app do hóspede e confirmar que aparece no cardápio.
  - **Dependencies:** Task 6.
  - **Files:** `apps/konekto_portal/lib/features/settings/room_service_settings_page.dart` (novo).
  - **Estimated scope:** M.

### Checkpoint: Padrão de catálogo validado
- [ ] Fluxo ponta a ponta de Room Service funcionando.
- [ ] Revisar com o usuário: o padrão (repositório + modelo + tela) serve pros outros 4 catálogos, ou precisa ajustar antes de replicar 4x?

### Phase 4 (REVISADA): Serviços Dinâmicos — substitui o plano original de "4 catálogos fixos"

**Por quê:** os 5 tipos fixos (Room Service, Spa, Restaurantes, Eventos, Passeios) não deixavam um hotel oferecer algo diferente desses 5. Decisão (ver spec, seção "Revisão de arquitetura"): modelo genérico `Service` → `ServiceItem`, hotel cria seus próprios serviços. Restaurantes vira um caso especial resolvido: cada restaurante é seu próprio `Service`.

**Novo schema Prisma:**
```prisma
model Service {
  id             String   @id @default(cuid())
  hotelId        String
  name           String
  slug           String
  icon           String            // nome do ícone Material (ex: "room_service", "spa", "restaurant", "event", "directions_bike")
  description    String
  bannerImageUrl String?
  position       Int      @default(0)
  enabled        Boolean  @default(true)
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt
  hotel          Hotel    @relation(fields: [hotelId], references: [id])
  items          ServiceItem[]
  @@unique([hotelId, slug])
  @@index([hotelId])
}

model ServiceItem {
  id          String   @id @default(cuid())
  serviceId   String
  name        String
  description String
  price       Float?   // null = não "comprável" (eventos/passeios só têm "solicitar/reservar", sem preço)
  imageUrl    String?
  location    String?  // usado por eventos/passeios
  category    String?  // agrupamento opcional (usado por room service: Entradas/Pratos/etc.)
  extraInfo   String?  // rótulo livre (tempo de preparo, duração, etc.)
  position    Int      @default(0)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  service     Service  @relation(fields: [serviceId], references: [id], onDelete: Cascade)
  @@index([serviceId])
}
```
`price: null` no item → guest app mostra "Solicitar"/"Reservar" em vez de preço + botão de pedido (cobre eventos/passeios sem precisar de um campo `buttonText` separado).

**Migração dos 5 tipos existentes** (rodada uma vez, substituindo os dados atuais — sem manter os dois sistemas em paralelo, já que são só dados de teste):
- Room Service → 1 `Service` (slug `room-service`), itens com `category` preenchido.
- Spa → 1 `Service` (slug `spa`), itens sem `category`.
- Restaurantes → **N `Service`** (um por restaurante, ex. `le-mare`, `la-piazza`), itens = `menuItems` de cada um.
- Eventos → 1 `Service` (slug `eventos`), itens com `price: null`, `location` preenchido.
- Passeios → 1 `Service` (slug `passeios`), itens com `price: null`, `location` preenchido.

#### Phase A: Modelo de dados + migração
- [x] **Task 8: Models `Service`/`ServiceItem` + migration.** Scope: XS. Files: `apps/konekto_api/prisma/schema.prisma`. Verify: `npx prisma migrate dev --name add_dynamic_services`. Migration `20260705025422_add_dynamic_services` aplicada no Neon.
- [x] **Task 9: Atualizar `prisma/seed.ts`** pra popular `Service`/`ServiceItem` a partir dos JSONs existentes (lógica de conversão descrita acima, incluindo explodir restaurantes em N serviços). Scope: M. Files: `apps/konekto_api/prisma/seed.ts`. Verify: `npm run db:seed`, conferir contagens no Prisma Studio (5 tipos → esperado: 1+1+N+1+1 services, onde N = nº de restaurantes no fixture).
  - Nota: `npx prisma generate` precisou ser rodado manualmente (client gerado estava desatualizado, sem os models novos — `prisma.service` retornava `undefined`).
  - Nota: casts `as unknown as Prisma.InputJsonValue` precisaram ser reaplicados nos 3 upserts de campo `Json` (hotel.config, hotelContent.data, brandContent.data) — mesmo padrão já usado nas rotas de API.
- [x] **Checkpoint A:** verificado via query direta (não Prisma Studio) — hotel_1: 7 services / 36 items (room-service 9, spa 4, le-mare 3, hanabi-sushi 3, toro-brasa 3, eventos 5, passeios 5); hotel_2: 1 service / 9 items (room-service, único fixture que hotel_2 tem). Total: 8 services, 41 items. `npm run build` limpo.

#### Phase B: Rotas de API
- [x] **Task 10: Rotas públicas de leitura** — `GET /api/hotels/:hotelId/services` (lista só `enabled: true`, ordenado por `position`) e `GET /api/hotels/:hotelId/services/:serviceId` (serviço + itens, ordenados por `position`). Scope: S. Files: `apps/konekto_api/app/api/hotels/[hotelId]/services/route.ts`, `.../services/[serviceId]/route.ts`.
- [x] **Task 11: Rotas de escrita de serviço** (gerente only, via `requireStaffRole`) — `POST` (criar), `PATCH` (editar nome/ícone/descrição/enabled/position), `DELETE` (remove serviço + itens em cascata). Scope: M. Files: mesmas rotas acima + método.
- [x] **Task 12: Rotas de escrita de item** (gerente only) — `POST /api/hotels/:hotelId/services/:serviceId/items`, `PATCH .../items/:itemId`, `DELETE .../items/:itemId`. Scope: M. Files: `apps/konekto_api/app/api/hotels/[hotelId]/services/[serviceId]/items/route.ts`, `.../items/[itemId]/route.ts`.
- [x] **Checkpoint B:** `curl` validado ponta a ponta contra o dev server local — `npm run build` limpo (5 rotas novas registradas); GET lista/detalhe públicos (200, sem token); POST serviço sem token (401); PATCH cross-hotel com gerente de outro hotel (403); POST/PATCH/DELETE de serviço e item com gerente correto (201/200); serviço "Aluguel de Bicicleta" (tipo 100% novo, fora dos 5 antigos) criado, populado com item, editado e removido com sucesso — prova antecipada do critério da Fase E. Achado: havia um dev server antigo (PID de uma sessão anterior) preso em porta 3000 com o client Prisma pré-regeneração, causando 500 (`Cannot read properties of undefined (reading 'findMany')`) — resolvido matando o processo e subindo um novo.

#### Phase C: Portal — gestão genérica de serviços
- [x] **Task 13: `ServiceRepository` + modelos Dart `Service`/`ServiceItem`** no portal (substitui `CatalogRepository`/`RoomServiceItem` da Fase 3 — supersedidos, não usados em paralelo). Scope: M. Files: `lib/models/service.dart`, `lib/data/service_repository.dart`.
- [x] **Task 14: Tela "Serviços" — lista + criar serviço novo.** Substitui os chips fixos (Marca/Room service/Spa/.../em breve) por: lista de serviços reais do hotel + botão "Criar serviço" (nome, ícone, descrição). Scope: M. Files: `lib/features/services/services_list_page.dart`, `lib/features/services/service_icons.dart`.
- [x] **Task 15: Tela de gestão de itens de um serviço** — reaproveita o padrão de `room_service_settings_page.dart` (lista + diálogo de item), generalizado pros campos opcionais (`price`, `location`, `category`, `extraInfo` sempre presentes no formulário mas opcionais — mais simples que esconder/mostrar condicionalmente por tipo de serviço). Scope: M. Files: `lib/features/services/service_items_page.dart`.
- [x] **Task 16: Remover código supersedido da Fase 3** (`catalog_repository.dart`, `room_service_item.dart`, `room_service_settings_page.dart`, `test/models/room_service_item_test.dart`, os chips fixos em `settings_page.dart` — agora só Marca/Serviços). Scope: S.
- [x] **Checkpoint C:** `flutter analyze` limpo, `flutter test` limpo (3/3), `flutter build web` limpo. Fluxo ponta a ponta validado via API (curl) na Fase B usando o mesmo contrato que o portal consome — criar/editar/gerenciar itens/remover confirmados no backend; navegação Marca↔Serviços e a tela de gestão de itens (lista→voltar) revisadas por leitura de código, não clicadas manualmente no Chrome (sem ferramenta de automação de browser disponível nesta sessão).
  - Nota: rotas `GET /services` e `GET /services/:id` foram ajustadas pra incluir serviços desabilitados quando o chamador é gerente do hotel (necessário pro portal conseguir reabilitar um serviço que ele mesmo desligou) — não estava no escopo original da Fase B, descoberto ao desenhar a tela de lista.

#### Phase D: App do hóspede — telas genéricas
- [x] **Task 17: `ServiceRepository` (somente leitura) + modelos Dart** no app do hóspede. Scope: S. Files: `lib/models/service.dart`. Em vez de um repositório separado, os métodos `getServices`/`getService` foram adicionados direto na interface `TenantRepository` já existente (mesmo padrão dos outros métodos de leitura) — implementados tanto em `HttpTenantRepository` (chama a API nova) quanto em `AssetTenantRepository` (sintetiza os services a partir dos JSONs bundled, portando a mesma lógica de conversão do `seed.ts`, pra não quebrar o modo padrão `USE_API=false`).
- [x] **Task 18: Lista de serviços genérica** — `services_page.dart` reescrito: busca `getServices(hotelId)` (em vez de ler `tenantConfig['servicesList']` fixo) e renderiza um card por serviço. Mantém o sistema de estilos vindo de `services_page.json` (banner, cores, fontes por tenant). Scope: M.
- [x] **Task 19+20: Telas genéricas de itens + detalhe.** Novos `service_items_list_page.dart` (lista de itens de um serviço, usa `TenantImage`) e `service_item_detail_page.dart` (detalhe — `price != null` mostra "Adicionar ao pedido", `price == null` mostra "Solicitar"; ambos simulam com SnackBar, igual ao comportamento antigo — Pedidos reais são fase futura). Scope: L, dividida em 2 arquivos como previsto.
- [x] **Task 21: Removidas as 10 telas antigas** (`room_service_page/detail`, `spa_services_list/detail`, `restaurant_list/detail`, `eventos_page/event_detail`, `passeios_page/detail`) + os métodos supersedidos da interface `TenantRepository` (`getRoomServiceMenu`, `getSpaServices`, `getSpaAvailability`, `getRestaurants`, `getRestaurantAvailability`, `getEventos`, `getEventAvailability`, `getPasseios`, `getPasseiosAvailability`) em ambas implementações. `mapa_page.dart`/`getMapaData` mantidos (fora de escopo — não é um catálogo de itens). `tenant_home_page.dart`: removida a chamada vestigial a `getRoomServiceMenu` (o resultado nunca era de fato usado pela `TenantHomeBody`).
- [x] **Checkpoint D:** `flutter analyze` limpo (só 8 lints pré-existentes, nenhum nos arquivos tocados), `flutter test` limpo, `flutter build web` limpo em **ambos** os modos (`USE_API=true` e padrão/asset). Dados verificados via curl contra a API viva: `GET /hotels/hotel_1/services` retorna os 7 services esperados (`room-service, spa, le-mare, hanabi-sushi, toro-brasa, eventos, passeios`) no mesmo formato que `Service.fromJson` espera. Sem verificação visual no Chrome (sem ferramenta de automação de browser nesta sessão — mesma limitação já registrada no Checkpoint C).
  - Achado (não relacionado às minhas mudanças): `flutter build web` no modo padrão falhou inicialmente com erros de `cloud_firestore_web`/`firebase_core_web` não encontrados — artefato de build cache (`.dart_tool/flutter_build/.../web_plugin_registrant.dart`) sobrando de antes da migração Firebase→Neon, já que o `pubspec.yaml` não tem mais nenhuma dependência Firebase. Resolvido com `flutter clean && flutter pub get`.

#### Phase E: Verificação end-to-end final
- [ ] Criar um serviço **totalmente novo** pelo portal (ex: "Aluguel de Bicicleta", sem equivalente nos 5 tipos antigos), adicionar 2 itens, confirmar que aparece no app do hóspede imediatamente — esse é o teste que prova que o problema original (hotel não conseguia criar serviço novo) foi resolvido.

### Checkpoint: Todos os catálogos
- [ ] Serviços dinâmicos completos: criar, editar, remover serviço e itens, tanto os 5 migrados quanto um novo criado do zero.
- [ ] `flutter analyze`/`flutter test` limpos nos dois apps Flutter; `npm run build` limpo na API.

### Phase 5: Convite de staff (`recepcao`)

- [x] **Task 12: Model `StaffInvite` + migration** — `id`, `code` (`@unique`), `hotelId`, `role` (`StaffRole`, default `recepcao`), `consumed`, `createdAt`. Migration `20260705035145_add_staff_invite` aplicada no Neon. Precisou `npx prisma generate` manual de novo (mesmo padrão da Fase A — o client gerado não pega os models novos automaticamente após `migrate dev`).

- [x] **Task 13: `POST /api/staff-invites`** — `requireStaffRole(['gerente'])`, gera código via `crypto.randomBytes(5).toString('hex').toUpperCase()` (10 chars), `hotelId` sempre de `staff.hotelId` (nunca do body), `role` hardcoded `'recepcao'` (nem aceito como input). Verificado via curl: 401 sem token, 201 com gerente.

- [x] **Task 14: `POST /api/staff-invites/:code/consume`** — pública, zod `{name, email, password (min 8)}`. Reivindica o convite atomicamente via `tx.staffInvite.updateMany({where:{code, consumed:false}, data:{consumed:true}})` dentro de `$transaction` e só cria o `Staff` se `count === 1` — evita duplicidade em corrida. Checa e-mail duplicado antes (409 `email_already_registered`). Retorna `{token, staff}` no mesmo formato de `/api/auth/login`. Verificado via curl: 200 válido, 409 reuso, 404 código inexistente, e login subsequente confirmado com `role: recepcao` e `hotelId` corretos.

- [x] **Task 15: Tela "Gerar convite"** — `invite_staff_page.dart`, virou a 3ª seção de Configurações ("Equipe", ao lado de Marca/Serviços — mesmo gate de `gerente` que as outras). Mostra link pronto (`Uri.base` + `?invite=<code>`) e o código puro, ambos com botão copiar (`Clipboard.setData`).

- [x] **Task 16: Tela de cadastro com convite** — `accept_invite_page.dart` (form nome/e-mail/senha) roteada em `main.dart` via `Uri.base.queryParameters['invite']`, checado *antes* do `StaffGate` normal (não precisa de login). Em caso de sucesso, `AuthRepository.signInWithToken` (método novo) persiste o token e busca `/auth/me`, depois substitui a rota por `StaffGate`, que cai direto no dashboard.
  - **Extra (não estava no escopo original das Tasks 12–16, mas fechava a lacuna do checkpoint):** `DashboardPage` agora filtra a aba "Configurações" do sidebar pra `recepcao` (antes aparecia pra todo mundo, só bloqueava o conteúdo internamente) — evita um beco sem saída de navegação.

### Checkpoint: Convite de staff completo
- [x] Fluxo ponta a ponta verificado via curl: gerente gera convite (201) → nova conta consome o código (200, token+staff com `role: recepcao`) → reuso do mesmo código rejeitado (409) → login da nova conta confirma o papel certo. `flutter analyze`/`flutter test`/`flutter build web` limpos no portal (API e web build também limpos). Sem verificação visual no Chrome (mesma limitação de sessão já registrada nos Checkpoints C/D — sem ferramenta de browser automation).
- [x] Confirmar com o usuário que o escopo de "Configurações" (Fase 5, sub-entrega 1) está completo — confirmado; deploy de produção (konekto_api + konekto_portal na Vercel, login.html apontando pros dois) validado ponta a ponta em produção antes de avançar.

## Fase Hóspedes (sub-entrega 2 do spec original)

Hoje o app do hóspede não tem NENHUM conceito de identidade individual: a "entrada" é um código único por hotel (`_HomePageBody._validateAccessCode()` em `home_konekto_page.dart`, casando contra `TenantsDirectoryRepository.getTenantsList()`), e o "check-in" (`CheckinStatusPage`) é 100% simulado — nome/quarto fixos vindos de um `guest_info.json` estático, o mesmo pra qualquer pessoa que entre naquele hotel. Não existe tabela de hóspedes, não existe código individual, não existe revogação.

**Decisão de design**: em vez de um segundo campo/tela de entrada, o mesmo campo "Código de Acesso" tenta resolver como código de HÓSPEDE primeiro (via `POST /api/guest/claim`); se não for um código de hóspede válido, cai no fluxo antigo de código de hotel, sem mudança nenhuma pro que já funciona. Isso cumpre a boundary do spec ("não remover o código único-por-hotel antes de Hóspedes estar completo e testado") sem exigir uma UI paralela confusa.

**Acesso**: `gerente` E `recepcao` podem gerenciar hóspedes (diferente de Configurações, que é só `gerente`) — a user story original é "como recepcionista".

### A: Modelo + auth de hóspede
- [x] **Task 1: Model `Guest` + migration.** `id`, `hotelId`, `name`, `roomNumber`, `accessCode` (`@unique`), `status` (enum `GuestStatus { active revoked }`, default `active`), `createdAt`. Migration `20260705224859_add_guest` aplicada no Neon.
- [x] **Task 2: `lib/guest-auth.ts`** — `signGuestToken`/`verifyGuestToken`, payload `{sub, hotelId, name, roomNumber}`, expiração 7 dias.
- [x] **Checkpoint A:** migration + `npx prisma generate` + `npm run build` limpos.

### B: Rotas de API
- [x] **Task 3: `POST /api/hotels/:hotelId/guests`** (gerente OU recepcao) — gera `accessCode` via `crypto.randomBytes(5).toString('hex').toUpperCase()` (mesmo gerador de staff-invites).
- [x] **Task 4: `GET /api/hotels/:hotelId/guests`** (lista ordenada por `createdAt` desc).
- [x] **Task 5: `DELETE /api/hotels/:hotelId/guests/:guestId`** (seta `status: revoked`).
- [x] **Task 6: `POST /api/guest/claim`** (público, código normalizado pra uppercase/trim, retorna `{token, guest}`).
- [x] **Checkpoint B:** `curl` validado — 401 sem token, 201 criar (gerente e recepcao), 200 listar, 200 claim (incluindo case-insensitive), 404 código inexistente, 200 revoke, 403 claim pós-revoke.

### C: Portal — tela Hóspedes
- [x] **Task 7: `GuestsRepository` + modelo Dart `Guest`.** Files: `lib/models/guest.dart`, `lib/data/guests_repository.dart`.
- [x] **Task 8: Tela "Hóspedes"** — lista (nome, quarto, status, código com botão copiar) + "Criar hóspede" (mostra o código gerado num diálogo pós-criação, com botão copiar) + revogar com confirmação. Substituiu o `PlaceholderSectionCard` do índice 0 no dashboard — disponível pra `gerente` e `recepcao` (não filtrado como Configurações). Files: `lib/features/guests/guests_page.dart`.
- [x] **Checkpoint C:** `flutter analyze`/`flutter test`/`flutter build web` limpos; CRUD já validado via curl contra o mesmo contrato no Checkpoint B.

### D: App do hóspede — entrada por código individual
- [x] **Task 9: `GuestClaimRepository`** — `claim(String code)` chamando `POST /api/guest/claim`, nunca lança (retorna `null` em qualquer falha, incluindo `useApi == false`), persiste o token via `shared_preferences` (dependência nova) pra uso futuro (Pedidos). Files: `lib/data/guest_claim_repository.dart`.
- [x] **Task 10: Integrado no `_validateAccessCode()` existente** — tenta `claim(rawInput)` primeiro; sucesso → vai direto pro `TenantHomePage` (pula o `CheckinStatusPage` fake, já que o claim em si já é a confirmação real); falha → cai no `_loadTenants()` de hoje sem nenhuma mudança. Files: `lib/app/home_konekto/home_konekto_page.dart`.
- [x] **Task 11: `TenantHomePage` ganhou `guestName`/`guestRoomNumber` opcionais** — quando presentes, substituem o registro estático de `getGuestInfo` só na exibição (wifi continua vindo do hotel, que é legitimamente compartilhado). Files: `lib/app/tenants/tenant_home_page.dart`.
- [x] **Checkpoint D:** `flutter analyze`/`flutter test`/`flutter build web` limpos (2 modos, mesmos 8 lints pré-existentes de sempre, nenhum novo). Ciclo completo via curl: criar hóspede → claim (nome/quarto/hotelId/token corretos) → `GET /api/hotels` (fluxo antigo) confirmado ainda em 200 → revogar → claim pós-revoke em 403.

### Checkpoint: Hóspedes completo
- [x] Recepção cria hóspede (nome+quarto) → recebe código → hóspede reivindica → nome/quarto reais confirmados na resposta → recepção revoga → novo claim do mesmo código falha (403). Validado via curl, contrato idêntico ao que o portal e o app consomem.
- [x] Código único-por-hotel (fluxo antigo) continua funcionando sem regressão — confirmado no mesmo teste acima.
- [ ] Confirmar com o usuário antes de iniciar Pedidos (que depende de Hóspedes existir). Sem verificação visual no Chrome/dispositivo real (sem browser automation nesta sessão) — recomendado testar manualmente o fluxo (portal cria hóspede → copia código → digita no app → app entra direto mostrando o nome/quarto reais).

## Fase Pedidos (sub-entrega 3, final do spec original)

**Ajuste em relação ao spec original**: o spec falava em "os 4 tipos entram juntos" (room service, spa, restaurante, passeios) porque na época esses eram tipos fixos no código. Como a Fase 4 substituiu isso por `Service`/`ServiceItem` genérico, um Pedido agora referencia um `ServiceItem` qualquer — não existe mais distinção por "tipo", então "os 4 tipos" vem de graça (qualquer serviço, incluindo um criado do zero pelo hotel, já pode gerar pedido).

**Botão existente**: `service_item_detail_page.dart` já tem "Adicionar ao pedido"/"Solicitar", hoje só um SnackBar de mentira. Vai virar um POST real — mas só quando o hóspede entrou por código individual (tem guest token salvo); se entrou pelo código antigo de hotel (sem identidade), mantém o SnackBar de simulação, já que não há hóspede pra vincular o pedido.

### A: Modelo + auth de hóspede em rota
- [x] **Task 1: Model `Order` + migration.** Migration `20260705230848_add_order` aplicada no Neon.
- [x] **Task 2: `requireGuestAuth`** em `lib/auth-guard.ts` (paralelo a `requireStaffRole`, usa `verifyGuestToken`).
- [x] **Checkpoint A:** migration + `npm run build` limpos.

### B: Rotas de API
- [x] **Task 3: `POST /api/orders`** — `itemName`/`price` sempre lidos do `ServiceItem` no servidor (snapshot, nunca do body); `guestId`/`hotelId` sempre do token.
- [x] **Task 4: `GET /api/hotels/:hotelId/orders`** — inclui `guest: {name, roomNumber}` via `include`.
- [x] **Task 5: `PATCH /api/hotels/:hotelId/orders/:orderId`** — atualiza `status`.
- [x] **Checkpoint B:** `curl` — 401 sem guest token, 201 criar pedido (snapshot correto de nome/preço), 200 listar (nome/quarto do hóspede presentes), 200 mudar status, 401 listar sem staff token.

### C: Portal — tela Pedidos com polling
- [x] **Task 6: `OrdersRepository` + modelo Dart `Order`.** Files: `lib/models/order.dart`, `lib/data/orders_repository.dart`.
- [x] **Task 7: Tela "Pedidos"** — lista (item ×qtd, preço total ou "Sob consulta", hóspede+quarto, badge de status, menu pra avançar status) + `Timer.periodic(5s)` cancelado no `dispose`. Substituiu o `PlaceholderSectionCard` do índice 1. Files: `lib/features/orders/orders_page.dart`.
- [x] **Checkpoint C:** `flutter analyze`/`flutter test`/`flutter build web` limpos. Polling verificado indiretamente (mesma limitação de sempre — sem browser automation): confirmei que uma nova consulta reflete dados criados depois via curl, que é exatamente o que o `Timer.periodic` reproduziria visualmente.

### D: App do hóspede — pedido real
- [x] **Task 8: `GuestClaimRepository.getStoredToken()`** — expõe o token salvo por `claim()`, mesmo padrão do `AuthRepository` do portal.
- [x] **Task 9: `OrdersRepository`** (app do hóspede) — `createOrder({serviceId, serviceItemId, token, quantity})`. Files: `lib/data/orders_repository.dart`.
- [x] **Task 10: `ServiceItemDetailPage` virou `StatefulWidget`** — `_confirm` agora é async: se existe guest token salvo, faz o `POST /api/orders` real (com spinner no botão enquanto envia, erro amigável em caso de falha); se não existe (fluxo antigo de código de hotel), mantém o SnackBar de simulação de sempre — zero regressão. Ganhou `serviceId` (antes só recebia o `item`), threaded a partir de `ServiceItemsListPage`.
- [x] **Checkpoint D:** `flutter analyze`/`flutter test`/`flutter build web` (2 modos) limpos — mesmos 8 lints pré-existentes, nenhum novo. Ciclo ponta a ponta via curl: criar hóspede → claim → `POST /api/orders` com o guest token (201, snapshot correto de nome/preço) → aparece na listagem do portal (`GET /api/hotels/:hotelId/orders`) com nome/quarto certos.

### Checkpoint: Pedidos completo (fecha o spec original inteiro)
- [x] Hóspede com identidade faz um pedido → aparece na listagem do portal com dados corretos (verificado via curl — polling em si não foi clicado visualmente, sem browser automation nesta sessão).
- [x] Hóspede sem identidade (fluxo antigo) não quebra — a lógica do fallback (`getStoredToken() == null` → SnackBar de simulação) foi revisada no código; sem clique manual real no navegador.
- [ ] Confirmar com o usuário antes de considerar a Fase 5 do spec original (Hóspedes/Pedidos/Configurações) inteiramente concluída.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| PATCH genérico de conteúdo permite salvar um JSON malformado que quebra o app do hóspede | Médio | Cada tela do portal só edita campos que ela própria conhece e serializa de volta o doc inteiro (não deixa o usuário editar JSON livre) |
| 4 catálogos com formatos diferentes geram 4 implementações praticamente do zero, mais trabalho que o esperado | Médio | Aceito conscientemente — YAGNI na abstração até ter 2+ exemplos reais (Room Service já serve de 1º exemplo) |
| Convite de staff sem expiração pode ser reusado se vazado antes de ser consumido | Baixo | Fora de escopo desta passada (`consumed: true` já impede reuso pós-cadastro); adicionar expiração é uma melhoria futura, não bloqueia esta entrega |

## Open Questions

- Formato exato de `eventos_data.json`/`passeios_data.json` (Tasks 10–11) — confirmar a chave do array e o shape do item antes de implementar (só vi o `pageConfig` no preview).

## Fase Hóspedes 2.0 — cadastro completo (substitui o cadastro mínimo nome+quarto)

Motivação: o cadastro mínimo (nome + quarto) da Fase Hóspedes original não bastava — precisava dos dados reais que um hotel coleta no check-in, e o fluxo antigo de "código único por hotel" (digitar `hotel_1` e cair direto como um hóspede fake fixo "Jeff Brito") ainda existia em paralelo, criando confusão. Resolvido:

**Decisões confirmadas com o usuário:**
1. Fluxo antigo de código de hotel **desativado de vez** — a única forma de entrar no app agora é um código individual de hóspede.
2. Senha de wifi pode ser **por hóspede** (opcional), com fallback pra senha padrão do hotel quando não definida.
3. Documento: **seletor de tipo (CPF/Passaporte/Outro) + campo de número**, não texto livre.

**Backend:**
- `Guest` expandido: `firstName`/`lastName`, `documentType` (enum) + `documentNumber`, `phoneCountryCode`/`phoneNumber`, `whatsappCountryCode`/`whatsappNumber` (opcionais), `email`/`address` (opcionais), `country`, `checkInDate`/`checkOutDate`, `wifiPassword` (opcional). Migration `20260710020533_expand_guest_profile` — limpou os 6 hóspedes/3 pedidos de teste antes de migrar (só dados de curl desta sessão, nenhum hotel real).
- `accessCode` agora prefixado com uma tag do próprio `hotelId` (ex: `HOTEL1-8F3A2B1C`) — só auditoria visual, a unicidade real já vem do `@unique`.
- `POST /api/guest/claim` resolve wifi: `guest.wifiPassword ?? hotel.guestInfo.wifi.password`; nome da rede sempre do hotel. Retorna perfil completo (nome, quarto, datas de estadia, wifi resolvido).
- `GuestTokenPayload`/rotas de staff atualizadas pra `firstName`/`lastName`.

**Portal:** formulário de cadastro completo (`intl_phone_field` pra telefone/WhatsApp com bandeira+código do país, seletor de tipo de documento, date pickers de check-in/check-out, checkbox "WhatsApp é o mesmo número"). Lista de hóspedes agora tem um "ver detalhes" (clique na linha) mostrando o cadastro inteiro.

**App do hóspede — remoção do fluxo antigo:** deletado `checkin_status_page.dart` e toda a lógica de casar "código de hotel" contra uma lista de tenants (`Tenant` model, `TenantsDirectoryRepository` + as duas implementações, `assets/data/tenants.json`) — nada mais referenciava esses símbolos fora do único call site removido. `TenantHomePage`/`ProfilePage` pararam de chamar `getGuestInfo` (removido de `TenantRepository` e ambas implementações) — `guestName`/`guestRoomNumber` viraram obrigatórios, e wifi passou a vir do claim em vez de um doc estático compartilhado.
  - **Consequência aceita**: o modo asset (`USE_API=false`, padrão sem dart-define) agora não leva a lugar nenhum além da tela de entrada — não há hóspedes cadastrados sem um backend real pra resolver contra. Isso é o resultado direto e esperado da decisão de desativar o fluxo antigo, não um bug.

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web` (2 modos) limpos nos dois apps Flutter, `npm run build` limpo na API — mesmos 8 lints pré-existentes de sempre, nenhum novo. Ciclo ponta a ponta via curl: criar hóspede com cadastro completo → claim (nome/quarto/wifi resolvido corretos) → pedido real → aparece no portal com o nome certo. Ainda **não deployado em produção** (só validado local) e sem clique manual no navegador (sem browser automation nesta sessão).

## Fase Hóspedes 3.0 — página de detalhe do hóspede + agrupamento por quarto (Stay) + aviso da recepção

**Status: concluído e em produção.**

Motivação: (1) a tela de Hóspedes do portal só abria um modal com os dados cadastrais — precisava virar uma página de verdade, mostrando cadastro completo, quarto, pedidos/reservas, e uma opção de "fechamento de conta" pro hóspede/estadia como um todo. (2) `Guest` era 1:1 com "uma pessoa com um código de acesso" — não existia nada que agrupasse várias pessoas do mesmo quarto (marido, esposa, filhos), cada uma com seu próprio código de login/pedidos, mas todas vinculadas à mesma "conta do quarto".

**Decisões confirmadas com o usuário:**
1. Nova entidade `Stay` (reserva/estadia) — a recepção cria a reserva do quarto uma vez (datas, número do quarto) e depois adiciona quantos hóspedes quiser dentro dela, cada um com seu próprio código de acesso.
2. Aviso da recepção pro quarto é só leitura (ex: "seu jantar está pronto") — hóspede visualiza, não responde. Chat com resposta fica pra uma fase futura.
3. Migração retroativa: 1 `Stay` por `Guest` já existente em produção (nenhum quarto compartilhado hoje, então 1:1 é exato, não uma aproximação).
4. "Fechar conta" mostra um resumo de consumo (soma de todos os pedidos de todos os hóspedes da estadia) antes de confirmar.

**Backend:**
- Novo model `Stay` (`id`, `hotelId`, `roomNumber`, `checkInDate`, `checkOutDate`, `status: active|closed`) e `StayNotice` (`stayId`, `message`, `createdAt`). `Guest` perdeu `roomNumber`/`checkInDate`/`checkOutDate` (agora vivem só em `Stay`) e ganhou `stayId` (FK obrigatória).
- Migration `20260710103328_add_stay_entity` — escrita à mão (não via `prisma migrate dev`, que se recusa em modo não-interativo quando há perda de dados) em 3 passos dentro da mesma transação: (1) cria as tabelas + `stayId` opcional, (2) backfill via `DO $$ ... FOR ... LOOP $$` criando uma Stay por Guest existente e linkando, (3) trava `stayId` como `NOT NULL` e remove as 3 colunas antigas. Verificado com `prisma migrate status` limpo depois.
- Rotas novas: `POST/GET /api/hotels/:hotelId/stays`, `GET/PATCH /api/hotels/:hotelId/stays/:stayId` (`PATCH {close:true}` fecha a estadia inteira e revoga todos os `Guest.accessCode` vinculados numa transação), `POST /api/hotels/:hotelId/stays/:stayId/notices`, `GET /api/guest/notices` (hóspede lê os avisos do próprio quarto).
- Rotas existentes atualizadas pra resolver quarto/datas via `guest.stay` em vez de campos diretos: `POST /api/hotels/:hotelId/guests` (agora exige `stayId`, valida que a Stay pertence ao hotel), novo `GET /api/hotels/:hotelId/guests/:guestId` (detalhe com `stay` + `orders` incluídos), `POST /api/guest/claim` (resolve `roomNumber`/datas via `guest.stay`, bloqueia se `stay.status === 'closed'`), `GET /api/hotels/:hotelId/orders` (achata `guest.stay.roomNumber` de volta pra `guest.roomNumber` na resposta, pra não quebrar o modelo Dart do portal).

**Portal:**
- Nova tela "Quartos" (`lib/features/rooms/rooms_page.dart` + `stay_detail_page.dart`): lista de estadias → detalhe com hóspedes vinculados (cada um navegável pro detalhe completo), campo de aviso, e "Fechar conta" (mostra o resumo de consumo somado de todos os hóspedes antes de confirmar).
- Nova página de detalhe do hóspede (`lib/features/guests/guest_detail_page.dart`) substitui o modal antigo — cadastro completo, quarto/estadia, lista de pedidos/reservas com status/preço/observação/agendamento, botão "Revogar acesso".
- Tela de Hóspedes (`guests_page.dart`) virou uma lista plana cross-quarto; "Criar hóspede" agora resolve o quarto inline (dropdown de estadias ativas + opção "Novo quarto" que revela os campos de quarto/datas na hora).
- Modelos novos: `lib/models/stay.dart` (`Stay`, `StaySummary`, `StayGuestSummary`, `StayNotice`, `GuestOrderSummary`, `NewStayInput`); `Guest` atualizado pra ler quarto/datas via `stay` aninhado (getters de conveniência `roomNumber`/`checkInDate`/`checkOutDate` mantêm o resto do código sem mudanças).

**App do hóspede:** novo ícone de sino no cabeçalho da home (`tenant_home_page.dart`) abre `notices_page.dart`, listando os avisos do quarto via `GET /api/guest/notices`.

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web` limpos nos dois apps Flutter (mesmos 8 lints pré-existentes, nenhum novo), `npm run build` limpo na API com todas as rotas novas geradas. Ciclo ponta a ponta via curl contra um servidor local apontando pro banco de produção: criar Stay → 2 hóspedes vinculados → claim de ambos → aviso enviado pela recepção → **ambos** leem o mesmo aviso → detalhe da Stay mostra os 2 hóspedes → fechar conta → claim de qualquer um dos dois falha com `access_revoked`. Deployado em produção (API + konekto-guest + konekto-portal), verificado via curl que os 3 domínios respondem corretamente pós-deploy.

## Fase Serviços 2.0 — tipo de serviço explícito (Serviço de Quarto / Restaurante / Atividade)

**Status: concluído e em produção.**

Motivação: o app do hóspede distinguia "Serviço de Quarto" do resto só comparando `slug == 'room-service'` client-side — funcionava por acidente (só existe um slug assim), mas não refletia uma decisão real do hotel nem permitia um terceiro comportamento. O usuário pediu 3 comportamentos distintos por tipo de serviço: Serviço de Quarto (pedido item a item, como já era), Restaurante (cardápio só informativo + um único botão "Reservar mesa" abaixo da lista, não por prato) e Passeio/Atividade (modal de dia/hora dentro de cada item, como já era pro resto).

**Backend:**
- Novo `enum ServiceType { room_service, restaurant, activity }` e `Service.type` (obrigatório, definido na criação, sem edição depois — mesmo padrão do `slug` imutável). Migration `20260710142343_add_service_type` — backfill dos 7 serviços já existentes (`slug='room-service'` → `room_service`, `icon='restaurant'` → `restaurant`, resto → `activity`), verificado correto via curl pós-deploy.
- Novo `ServiceItem.hidden` (Boolean, default false) — marca um item técnico que nunca aparece em nenhuma listagem (portal ou hóspede). `GET /api/hotels/:hotelId/services/:serviceId` agora filtra `hidden: false` nos itens embutidos.
- `POST /api/orders`: `serviceItemId` virou opcional. Se omitido, só vale pra um `Service` do tipo `restaurant` (senão 404) e exige `scheduledFor` (senão 400) — reserva a MESA do restaurante, resolvendo/criando (find-or-create) um `ServiceItem` oculto "Reserva de mesa" reaproveitado entre reservas do mesmo restaurante, reusando o `Order` existente sem tabela nova.

**Portal:** modelo `Service` ganhou `type` (`ServiceType` enum Dart espelhando o backend). Tela de Serviços agora agrupa a lista em 3 seções por tipo; "Criar serviço" ganhou um seletor de tipo (chips) só na criação — ao editar, o tipo aparece como rótulo fixo, não editável.

**App do hóspede:** `Service.type` substitui o antigo getter `isRoomService` baseado em slug. `ServiceItemDetailPage` ramifica em 3: `roomService` (quantidade+observação, inalterado), `activity` (dia/hora por item, inalterado), `restaurant` (sem botão nenhum — só informativo). `ServiceItemsListPage` ganhou um botão fixo "Reservar mesa" no rodapé quando `type == restaurant`, abrindo o `showBookingSheet` (dia/hora) e chamando `OrdersRepository.createTableReservation` (novo método, POST sem `serviceItemId`).

**Checkpoint:** `flutter analyze`/`flutter test` limpos nos dois apps, `npm run build` limpo na API. Ciclo ponta a ponta via curl contra servidor local (banco de produção): backfill dos 7 serviços confirmado correto → reserva de mesa criada duas vezes reaproveitando o mesmo item oculto (sem duplicar) → item oculto nunca aparece no cardápio (contagem de itens visíveis inalterada) → reserva de mesa contra um serviço não-restaurante rejeitada com 404 → as 2 reservas aparecem certas em "Meus Pedidos". Deployado em produção (API + konekto-guest + konekto-portal), verificado via curl que os 3 domínios respondem corretamente pós-deploy, incluindo o `type` de cada serviço já correto na resposta pública.

## Fase Serviços 2.1 — categoria livre e extensível (separada de comportamento)

**Status: concluído e em produção.**

Motivação: logo depois de shippar os 3 `ServiceType` fixos como seções da lista do portal, o usuário apontou dois problemas — (1) contraste ruim no chip selecionado do seletor de tipo (fundo dourado translúcido + texto dourado claro, quase ilegível), e (2) precisava poder criar categorias novas além das 3 fixas (ex: "Lavanderia", "Transfer"). Como `type` decide COMPORTAMENTO real no app do hóspede (3 branches de código: pedido, reserva de mesa, agendamento por item), abrir esse enum pra qualquer string quebraria o app assim que aparecesse um valor desconhecido. Resolvido separando os dois conceitos.

**Decisão confirmada com o usuário:** categoria nova = escolher um dos 3 comportamentos já existentes por trás (não comportamento 100% customizável, que exigiria um construtor de formulário — fora de escopo).

**Backend:** novo `Service.category` (String, livre, obrigatório) — `type` continua os mesmos 3 valores fixos, imutável após criação; `category` é só rótulo de organização visual e pode ser editada depois via `PATCH` (diferente de `type`, que nem está no schema do PATCH). Migration `20260711025805_add_service_category` — backfill: cada serviço existente ganhou a categoria com o nome da seção fixa que já ocupava (`room_service`→"Serviço de Quarto", `restaurant`→"Restaurante", `activity`→"Passeio / Atividade"), sem mudança visual pra quem já tinha serviços.

**Portal:** lista agora agrupa por `category` (valores distintos, ordem de primeira aparição) em vez do enum fixo. Formulário de criação/edição: seção "Comportamento no app do hóspede" (os 3 chips, só na criação, trava depois — contraste corrigido pra fundo dourado sólido + texto `KonektoBrand.ink`, mesmo padrão dos botões "Salvar"/"Criar conta" do resto do portal) + nova seção "Categoria" (dropdown com as categorias já usadas no hotel + opção "+ Nova categoria" que revela um campo de texto — editável tanto na criação quanto depois, em qualquer serviço).

**Checkpoint:** `flutter analyze` limpo no portal, `npm run build`/`tsc --noEmit` limpos na API. Ciclo ponta a ponta via curl contra servidor local (banco de produção): backfill dos 7 serviços confirmado correto → categoria customizada "Lavanderia" criada com sucesso (`type: activity`) → categoria editada depois via PATCH (`type` continuou intacto) → tentativa de mudar `type` via PATCH sem efeito (campo nem existe no schema). Deployado em produção (API + konekto-portal — app do hóspede não precisou de rebuild, só lê `type`, nunca `category`).

## Itens abertos (pendências conhecidas, não bloqueiam)

- Nenhum item aberto no momento. Duas telas mortas no app do hóspede (`HistoryPage`, `MapaPage`) seguem existindo mas desconectadas de qualquer fluxo real — decisão de construir de verdade ou remover ainda pendente, não urgente.

## Fase Quartos 2.0 — cadastro de quarto físico, mapa visual, edição de hóspede

**Status: concluído e em produção.**

Motivação: três pedidos do usuário na mesma leva — (1) editar o cadastro de um hóspede já existente (só dava pra revogar, não corrigir um dado errado); (2) a tela "Quartos" listava estadias, não tinha noção de "quarto livre" (só existiam quartos que alguém já tinha ocupado alguma vez); (3) não existia um cadastro de quartos físicos do hotel em si — `Stay.roomNumber` era texto livre digitado toda vez.

**Decisão confirmada com o usuário:** `Room` vira uma entidade real (cadastro em Configurações), e `Stay` passa a referenciar um `Room` via FK — "Nova estadia" escolhe um quarto já cadastrado em vez de digitar o número. Isso é o que torna o mapa de quartos coerente (todo quarto que existe no mapa é um quarto de verdade, cadastrado).

**Backend:**
- Novo model `Room` (`number` único por hotel, `description` livre). `Stay.roomNumber` virou `Stay.roomId` (FK). Migration `20260711032854_add_room_entity` — backfill: um `Room` por par (hotelId, roomNumber) distinto já usado em alguma Stay (4 quartos reais migrados sem perda: 210/305/412/701), verificado correto via query direta pós-migração.
- Novo helper `lib/stay-shape.ts` (`flattenStayRoomNumber`) — todo lugar que retorna uma Stay (ou um Guest/Order com Stay aninhada) inclui `room: {select:{number}}` e achata de volta pra `roomNumber` na resposta, mantendo o formato que os 3 apps já esperavam sem precisar mexer em nenhum modelo Dart além do que já mudou de qualquer forma.
- Novas rotas: `GET/POST /api/hotels/:hotelId/rooms` (lista já vem com a estadia ATIVA de cada quarto, incluindo hóspedes+pedidos — dá pro mapa mostrar livre/ocupado e o valor em aberto numa chamada só), `PATCH/DELETE /api/hotels/:hotelId/rooms/:roomId` (`DELETE` rejeita com 409 se o quarto já teve alguma Stay, histórica ou ativa). `POST /api/hotels/:hotelId/stays` e `PATCH .../stays/:stayId` trocaram `roomNumber` por `roomId` (valida que o quarto existe e pertence ao hotel).
- Novo `PATCH /api/hotels/:hotelId/guests/:guestId` — edita só dados pessoais (nome, documento, contato, wifi); não mexe em `stayId`/quarto (mover hóspede de quarto fica pra outra hora) nem `accessCode`/`status` (fluxos próprios).

**Portal:**
- Configurações ganhou uma 4ª aba "Quartos" (`room_registry_page.dart`) — CRUD simples de quarto físico (número + descrição livre), mesmo padrão visual da lista de Serviços.
- `GuestDetailPage` ganhou um botão "Editar cadastro" na seção Cadastro, abrindo um formulário pré-preenchido (mesmos campos pessoais da criação, sem quarto/estadia).
- `RoomsPage` (aba principal "Quartos") virou um mapa visual — grade de cards por quarto, ícone+badge livre/ocupado, e pra quartos ocupados já mostra hóspedes+valor em aberto no próprio card. Tocar num quarto ocupado abre `StayDetailPage` (que ganhou um "Valor em aberto" permanente no corpo — não só na confirmação de fechar conta — e um botão "Estender estadia" que só troca o `checkOutDate`); tocar num quarto livre abre um atalho simples "Iniciar nova estadia" (dia de check-in/check-out, quarto já fixo).

**Checkpoint:** `flutter analyze`/`flutter test` limpos no portal, `tsc --noEmit`/`next build` limpos na API. Ciclo ponta a ponta via curl contra servidor local (banco de produção): quarto novo criado → número duplicado rejeitado com 409 → Stay criada nele via `roomId` → quarto aparece OCUPADO no mapa → estender estadia (`checkOutDate` novo) → tentativa de apagar quarto com Stay vinculada rejeitada com 409 → edição de cadastro de hóspede (nome+e-mail) aplicada e revertida corretamente, `stay.roomNumber` continua achatado certo na resposta. Deployado em produção (API + konekto-portal — app do hóspede não precisou de rebuild, o achatamento de `roomNumber` mantém o contrato que ele já espera).

## Fase Quartos 2.1 — lista de pedidos no detalhe do quarto

**Status: concluído e em produção.**

Motivação: o "Valor em aberto" mostrado no topo de `StayDetailPage` não tinha nenhuma lista de pedidos abaixo pra justificar o número — o usuário pediu pra ver o detalhamento (o que foi pedido, por quem, quando, quanto) logo abaixo do campo de enviar aviso.

**Portal:** `StayDetailPage` ganhou uma seção "Pedidos" no fim da página — achata `stay.guests[].orders[]` numa lista única ordenada por `createdAt` desc, mostrando quantidade + nome do item, hóspede (só quando há mais de um no quarto) + horário, observação (se houver), valor (`price * quantity`) e badge de status. Nenhuma mudança de API — os dados já vinham nested na resposta de `GET /stays/:stayId`.

## Fase Dashboard 1.0 — Visão Geral com gráficos operacionais

**Status: concluído e em produção.**

Motivação: a aba "Hóspedes" era a primeira tela que o staff via ao entrar no portal — não existia nenhuma visão consolidada do que hotéis/pousadas realmente acompanham no dia a dia (ocupação, receita, o que está vendendo, quem está chegando/saindo).

**Decisão de escopo:** todas as métricas vêm de dados que já existem no schema (Room, Stay, Guest, Order, Service.category) — nada de tracking novo. Agregação inteira feita no servidor numa única chamada, pra não trafegar o histórico de pedidos inteiro pro portal.

**Backend:** novo `GET /api/hotels/:hotelId/dashboard/stats` (staff `gerente`/`recepcao`) — calcula em uma única resposta: ocupação (quartos cadastrados vs. com estadia ativa), hóspedes ativos, receita (hoje / 7 dias / 30 dias, soma de `price * quantity` de pedidos não cancelados), série diária de receita (14 dias), contagem de pedidos por status (30 dias), receita por `Service.category` (30 dias), top 5 itens mais pedidos por receita (30 dias), ticket médio por hóspede (receita 30d / hóspedes distintos com pedido cobrável), e as estadias com check-in ou check-out previstos pros próximos 7 dias. `Order` não tem relação Prisma direta com `Service` (só guarda `serviceId` solto) — resolvido buscando os `Service` distintos dos pedidos do período numa segunda query e montando um mapa `serviceId → category` em memória.

**Portal:** nova dependência `fl_chart`. Nova seção "Visão Geral" (`dashboard_overview_page.dart`) — vira a **primeira aba do sidebar** (antes era "Hóspedes"). Layout: cards de KPI no topo (ocupação, hóspedes ativos, receita hoje, receita 30 dias + ticket médio); gráfico de barras de receita dos últimos 14 dias; dois donuts lado a lado (pedidos por status, receita por categoria) que empilham em telas estreitas; ranking dos itens mais pedidos como barras horizontais; e duas listas lado a lado de chegadas/saídas previstas pros próximos 7 dias. Novo `lib/models/dashboard_stats.dart` + `lib/data/dashboard_repository.dart` seguindo o mesmo padrão de repositório do resto do portal.

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web --release` limpos no portal, `tsc --noEmit` limpo na API. Endpoint testado via curl contra servidor local (banco de produção) — confirmado ocupação 4/4 quartos, receita agregada batendo com os pedidos reais (R$120 massagem + R$155 restaurante em dois dias distintos), categorias e top itens corretos, check-outs previstos aparecendo certos pros 4 quartos ocupados.

## Fase Marca 1.1 — Wi-Fi padrão do hotel e carrossel de destaque

**Status: concluído e em produção.**

Motivação: levantamento do que existe no app do hóspede sem contrapartida no portal. Achamos dois casos reais — a home do hóspede sempre mostra um card de "Wi-Fi" (rede + senha) e um carrossel de imagens de destaque, mas nenhum dos dois tinha editor nenhum no portal: o Wi-Fi só existia se alguém escrevesse direto no banco (`HotelContent` doc `guestInfo`), e o carrossel usava caminhos de asset local empacotados no app (`assets/tenant_assets/...`), então mesmo colando uma URL não haveria como o app renderizar.

**Backend:**
- `PATCH /api/hotels/:hotelId` — schema aceita agora `hotelInfo.promoImages` (`images[]`, `carouselHeight`, `carouselEnabled`), sempre substituindo o objeto inteiro.
- `PATCH /api/hotels/:hotelId/content/:docName` — trocou de `update` (exigia o doc já existir, 404 senão) pra `upsert`, porque nem todo hotel tem o doc `guestInfo` semeado de antemão; sem isso o primeiro save do Wi-Fi de um hotel novo quebraria.

**App do hóspede (`konekto_mobile`):** `ImageCarousel` (usado na home, depois do login) trocou `Image.asset` fixo por `TenantImage` — o mesmo widget que já decide entre asset local e `Image.network` pra imagens de item de serviço, olhando se a URL começa com `http(s)://`. Sem essa troca, uma URL configurada no portal simplesmente não apareceria (a Correção de imagem de item via URL externa segue como pendência separada, ver "Itens abertos" — esse era um bug de CORS/hotlink; aqui o problema era mais básico, o widget nem tentava carregar de rede).

**Portal:** Configurações → Marca ganhou dois cards novos, entre o QR code de recepção e o card de marca existente: "Wi-Fi padrão" (nome da rede + senha, lidos/salvos em `HotelContent.guestInfo.wifi`) e "Carrossel de destaque" (lista dinâmica de URLs de imagem, adicionar/remover linha, salva a lista inteira em `hotelInfo.promoImages`). Cada card carrega e salva de forma independente do card de marca original (nome/logo/cores), sem alterar `updateBranding` nem o teste existente dele.

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web --release` limpos no portal e no app do hóspede, `tsc --noEmit` limpo na API. Testado via curl contra servidor local (banco de produção): PATCH de `promoImages` com URLs reais e reversão pro asset original; PATCH de Wi-Fi num doc já existente e upsert num doc novo (criado e removido de teste depois).

## Fase Segurança 1.0 — auditoria de segregação multi-tenant

**Status: concluído e em produção.**

Motivação: usuário perguntou se a segregação entre hotéis clientes era garantida de ponta a ponta, antes de começar a onboardar clientes pagantes de verdade. Rodamos uma auditoria dedicada (agente `security-reviewer`) em todas as 26 rotas de `app/api/**/route.ts`, focada especificamente em IDOR e vazamento cross-tenant (não em OWASP genérico).

**Achado CRÍTICO (corrigido):** `GET /api/hotels/:hotelId/content/:docName` não tinha autenticação nenhuma. O doc `guestInfo` guarda a senha de wifi do hotel em texto puro — qualquer pessoa descobria um `hotelId` via `GET /api/hotels` (rota pública, lista todo mundo) e lia a senha de wifi de qualquer hotel cliente sem login nem código de acesso. A própria feature de Wi-Fi padrão que shippamos na fase anterior usava essa mesma rota insegura. Corrigido com uma lista de docs sensíveis (`PRIVATE_DOC_NAMES`, hoje só `guestInfo`) que agora exige staff autenticado do mesmo hotel; os docs genuinamente públicos que o app do hóspede já lia sem token (`servicesPage`, `mapa`) continuam exatamente como estavam — confirmado via `grep` que nenhum outro doc sensível existe hoje e que nada mais chama essa rota sem token.

**Achado leve (corrigido):** `hotelInfo.accessCode` — campo legado de antes do modelo de `Guest.accessCode` individual existir — sobrevivia no `Hotel.config` dos 2 hotéis de produção e era devolvido por `GET /api/hotels/:hotelId` (rota pública). Confirmado via grep que nenhum código lê esse campo hoje (morto, não é um controle de acesso funcional), mas removido mesmo assim por parecer um segredo válido — script pontual limpou os 2 hotéis existentes e o seed data.

**Endurecimento defensivo (corrigido):** `GET /dashboard/stats` resolvia a categoria de cada serviço por `id`, sem filtro de `hotelId` — não explorável hoje (todo pedido só existe se o serviço já foi validado como do mesmo hotel na criação), mas adicionado o filtro mesmo assim pra não depender desse invariante silenciosamente pra sempre.

**Tudo o mais auditado ficou confirmado correto:** toda rota de staff que mexe num recurso aninhado (hóspede, quarto, estadia, serviço, item, pedido) filtra tanto pela URL (`staff.hotelId !== hotelId` → 403) quanto na query em si; toda rota autenticada de hóspede deriva `hotelId`/`guestId` só do token verificado, nunca do body; o fluxo de convite de staff trava `role: recepcao` e o `hotelId` do convite, sem campo livre; JWT de staff/hóspede só é assinado a partir de um registro do banco recém-verificado, nunca de input do cliente.

**Checkpoint:** `tsc --noEmit` limpo. Testado local contra banco de produção: `guestInfo` sem token → 401; com token de gerente do próprio hotel → 200 (conteúdo correto); `servicesPage` (doc público) sem token → 200 (comportamento inalterado); `GET /api/hotels/hotel_1` não retorna mais `accessCode`.

## Fase Clientes 1.0 — histórico consolidado de hóspedes

**Status: concluído e em produção. Envio de e-mail/cupons fica pra uma fase futura, quando houver uma conta de provedor de e-mail configurada.**

Motivação: usuário pediu uma página de "Clientes" — histórico de quem já se hospedou, quando, por quanto tempo, quanto gastou — pra eventualmente enviar promoções e cupons. Combinamos dividir em duas partes: histórico agora (sem depender de nada externo), envio de e-mail depois (precisa de conta num provedor tipo Resend + domínio verificado).

**Decisão de modelagem:** não existe uma tabela "Cliente" própria — cada estadia gera um `Guest` novo (mesmo se for a mesma pessoa voltando). Em vez de migrar o schema, a API agrega por `documentNumber` (CPF/passaporte) na hora, em memória — suficiente pra escala de um hotel/pousada e evita manter uma tabela derivada sincronizada com `Guest`/`Stay`/`Order`.

**Backend:** novo `GET /api/hotels/:hotelId/customers` (staff `gerente`/`recepcao`) — busca todos os `Guest` do hotel com a `Stay` (datas, quarto) e `Order`s (preço × quantidade) de cada um, agrupa por `documentNumber`, e devolve por cliente: nome/contato mais recente, `visitsCount`, `totalSpent`, `firstVisit`, `lastVisit`, e a lista completa de estadias (quarto, datas, noites, valor gasto naquela estadia).

**Portal:** nova aba "Clientes" no sidebar (depois de Hóspedes). Lista com busca (nome/documento) e ordenação (última visita/total gasto/visitas/nome); cada linha mostra nome, contato, badge de visitas, total gasto e última visita. Detalhe do cliente (mesmo padrão `onBack` de conteúdo-no-lugar): contato completo, cards de estatística (visitas/total gasto/primeira e última visita), histórico completo de estadias, e um aviso "em breve" no lugar de um botão de enviar e-mail que ainda não existe (evita uma ação fake na tela).

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web --release` limpos no portal, `tsc --noEmit` limpo na API. Testado via curl contra servidor local (banco de produção): 4 clientes agregados corretamente a partir dos hóspedes existentes, cada um com 1 visita (nenhum repetiu documento ainda), `totalSpent` batendo com os pedidos reais de cada hóspede.

## Fase Cupons 1.0 — cupons/promoções aplicados direto no pedido (estilo iFood)

**Status: concluído e em produção.**

Motivação: usuário pediu uma aba em Configurações pra criar cupons de desconto/promoções que o hóspede pudesse usar direto no app. Perguntamos o nível de integração — se era só informativo (hóspede vê e apresenta o código pra recepção aplicar manualmente) ou se o desconto devia ser aplicado automaticamente no pedido. Resposta: aplicado automaticamente, mas sem o hóspede digitar código nenhum — ele escolhe da lista de cupons elegíveis, igual ao seletor de cupom do iFood.

**Decisão de modelagem (o que evita reabrir todo o resto do app):** `Order.price` continua sendo o preço FINAL por unidade (já com desconto embutido, se houver) — exatamente como já era antes de cupons existirem. Isso significa que todo cálculo de receita que já existia (`price * quantity` em `StayDetailPage`, no mapa de quartos, no dashboard) continua correto automaticamente, sem precisar tocar em nenhum desses lugares. `discountAmount` e `couponId` só existem como informação extra pra exibição/auditoria (quanto foi descontado, qual cupom foi usado) — nunca entram em nenhuma soma.

**Backend:**
- Novo model `Coupon` (título, descrição, `code` só pra referência interna do staff — o hóspede nunca digita, tipo de desconto percentual/valor fixo, pedido mínimo opcional, validade opcional, limite de uso total opcional, limite por hóspede — padrão 1). `Order` ganhou `couponId`/`discountAmount` opcionais. Migration `20260712050920_add_coupons` (aditiva, sem perda de dado).
- `GET/POST /api/hotels/:hotelId/coupons` + `PATCH/DELETE /api/hotels/:hotelId/coupons/:couponId` — CRUD do portal, só `gerente` cria/edita/remove; `DELETE` rejeita com 409 se o cupom já foi usado em algum pedido (usar o toggle `enabled` pra aposentar em vez de apagar).
- Novo `GET /api/coupons` (guest-authenticated) — cupons ativos e dentro da validade do hotel do hóspede (sempre do token, nunca de input), cada um já anotado com `eligible` (falso se o limite de uso, total ou por hóspede, já foi atingido).
- `POST /api/orders` — aceita `couponId` opcional (só no branch de item com preço; reserva de mesa não tem preço, não aplica). Revalida tudo de novo no servidor antes de aplicar (elegibilidade pode ter mudado entre o hóspede abrir a lista e confirmar): cupom existe/ativo/dentro da validade, pedido bate o mínimo, limite total e por hóspede não estourados. Calcula o desconto (percentual ou valor fixo, nunca passa do subtotal) e grava `price` já com desconto + `discountAmount`/`couponId` como metadado. `PATCH /api/orders/:orderId` passou a rejeitar mudança de quantidade em pedido com cupom aplicado (evitaria descasar o desconto já travado) — pede pra cancelar e refazer nesse caso raro.

**Portal:** Configurações ganhou uma 5ª aba "Cupons" (`coupons_page.dart`) — mesmo padrão CRUD de Serviços/Quartos, com chips de tipo de desconto, campos de pedido mínimo/limites, seletores de data de validade, e um `Switch` pra ativar/desativar rápido sem abrir o formulário. `Pedidos` e o detalhe do quarto (`StayDetailPage`) agora mostram uma tag "🏷 Nome do cupom (-R$X)" em pedidos que usaram cupom.

**App do hóspede:** o modal de quantidade/observação do Serviço de Quarto (`order_quantity_note_sheet.dart`) ganhou uma lista horizontal de cartões de cupom — "Sem cupom" + cada cupom elegível buscado na hora (nunca em cache, pra não mostrar um cupom já expirado/usado), com os inelegíveis visíveis mas desabilitados mostrando o motivo ("já usado", "mín. R$X"). Busca os cupons disponíveis (`GET /api/coupons`) só quando o item tem preço. "Meus Pedidos" mostra a mesma tag de cupom aplicado que o portal.

**Fora de escopo desta fase (deliberado):** cupom em reservas de restaurante/atividade (`booking_sheet.dart`) — só no fluxo de Serviço de Quarto por enquanto; cupom restrito a um serviço específico — hoje é sempre hotel inteiro.

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web --release` limpos nos 3 apps, `tsc --noEmit` limpo na API. Ciclo ponta a ponta via curl contra servidor local (banco de produção), com quarto/estadia/hóspede de teste criados e removidos ao final: cupom de 20% criado → hóspede vê `eligible: true` → pedido de 2x um item de R$25 com o cupom → preço final gravado corretamente em R$20/unidade, `discountAmount: 10` → segunda tentativa do mesmo hóspede com o mesmo cupom rejeitada com 409 (limite por hóspede) → staff vê o pedido com o título do cupom anexado → tentativa de apagar o cupom já usado rejeitada com 409 → desativado com sucesso em vez disso.

## Fase Imagens 1.0 — proxy de imagem corrige CORS de URL externa

**Status: concluído e em produção.**

Motivação: pendência aberta desde a Fase Serviços — imagens de item com URL externa (colada no portal) não carregavam no app do hóspede. Causa raiz confirmada: Flutter Web usa CanvasKit, que baixa os bytes da imagem via `fetch()` do navegador pra decodificar numa textura (diferente de uma tag `<img>` comum) — isso exige que o host de origem responda com cabeçalho CORS liberado, o que a grande maioria dos sites onde alguém cola uma URL de imagem não configura. Nenhuma URL de terceiro ia funcionar de forma confiável sem contornar isso.

**Decisão:** proxy de imagem no backend (`GET /api/image-proxy?url=...`) em vez de pedir pra hotéis usarem hosts específicos ou construir upload de arquivo (maior escopo, adiado). O proxy busca a imagem no servidor — sem restrição de CORS ali — e devolve com `Access-Control-Allow-Origin: *`, funcionando com qualquer origem.

**Backend:** rota pública (sem auth, mesma lógica de catálogo público) com proteção contra SSRF, já que é um endpoint que busca qualquer URL informada: só `http`/`https`, resolve o hostname via DNS antes de buscar e rejeita IPs privados/reservados (inclui bloqueio do endpoint de metadata de nuvem `169.254.169.254`, protege contra DNS rebinding), segue redirecionamentos manualmente (até 3, revalidando o host a cada um em vez de confiar no `redirect: 'follow'` do fetch), limita a 8MB (checado tanto pelo `Content-Length` quanto durante o download, caso o header minta), timeout de 8s, e só aceita `Content-Type` de imagem de verdade (rejeita qualquer outra coisa com 415). Resposta cacheada por 7 dias (`Cache-Control` com `s-maxage`) já que a mesma URL sempre devolve a mesma imagem.

**App do hóspede:** `TenantImage` — o único lugar que renderiza imagem de rede no app (itens de serviço e o carrossel de destaque) — passou a montar a URL através do proxy em vez de `Image.network(url)` direto. Nenhuma outra mudança: portal continua só guardando a URL original digitada pelo hotel, sem saber nada do proxy.

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web --release` limpos no app do hóspede, `tsc --noEmit` limpo na API. Testado local: imagem pública real proxeada com sucesso (PNG válido, cabeçalhos corretos) → bloqueio confirmado pra endpoint de metadata de nuvem, `localhost`, protocolo `file://` e `Content-Type` não-imagem.

## Limpeza — remoção de código morto (Histórico/Perfil pré-login, Mapa do hotel)

**Status: concluído e em produção.**

Motivação: revisão do que ficava pendente das últimas fases apontou duas telas do app do hóspede nunca conectadas a nenhum fluxo real. Investigando de perto, achamos algo pior que "inacabado": as abas "Histórico" e "Perfil" apareciam no rodapé da tela de entrada **antes** do hóspede digitar qualquer código de acesso — ou seja, visíveis pra qualquer visitante do app. "Histórico" mostrava estadias fictícias fixas no código; "Perfil" mostrava um nome hardcoded (não genérico, o nome de uma pessoa real) como se fosse a conta logada. Não era feature inacabada, era sobra de protótipo mostrando dado fake/pessoal pra estranhos. Decisão: remover as duas, mais o "Mapa do hotel" (`MapaPage`, sem dado fake mas também nunca instanciado em lugar nenhum).

**Removido:** `lib/app/home_konekto/history_page.dart`, `lib/app/home_konekto/profile_page.dart`, `lib/app/tenants/mapa_page.dart` — arquivos inteiros apagados. `HomeKonektoPage` (tela de entrada) simplificada de `StatefulWidget` com `BottomNavigationBar` de 3 abas pra `StatelessWidget` mostrando só `_HomePageBody` (formulário de código de acesso + QR + carrossel de promoções) — a experiência real que já era o único caminho funcional. `getMapaData` removido de `TenantRepository` (interface) e das duas implementações (`AssetTenantRepository`, `HttpTenantRepository`), já que `MapaPage` era o único consumidor.

**Fora do escopo:** os arquivos de seed `mapa_data.json` (`assets/tenant_assets/hotels/*/mapa_data.json`) ficaram no repositório — dado estático órfão, inofensivo, não vale o risco de mexer no manifesto de assets pra isso agora.

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web --release` limpos — nenhuma referência restante a `MapaPage`/`HistoryPage`/`getMapaData`/`mapa_data` em nenhum arquivo `.dart` (confirmado via grep).

## Fase Quartos 2.1 — mapa seccionado + ocupação com busca de hóspede por documento

**Status: concluído e em produção.**

Motivação: usuário apontou que o fluxo de ocupar um quarto estava confuso — o mapa misturava livres/ocupados sem separação visual, e ocupar um quarto exigia dois passos desconectados (um modal só de datas pra criar a Stay, depois abrir o quarto de novo e usar OUTRO modal pra adicionar o hóspede, sempre do zero, sem nenhuma forma de reaproveitar o cadastro de alguém que já se hospedou antes).

**Backend:** novo `GET /api/hotels/:hotelId/guests/lookup?documentNumber=X` (staff `gerente`/`recepcao`) — acha o cadastro mais recente de um `Guest` pelo documento (CPF ou passaporte/outro se estrangeiro) dentro do hotel, devolve os dados pessoais pra reaproveitar, ou 404 se for realmente um hóspede novo. Convive sem conflito com a rota dinâmica existente `guests/[guestId]` (Next.js resolve o segmento estático "lookup" antes do dinâmico).

**Portal — mapa de quartos:** `RoomsPage` agora renderiza duas seções sempre visíveis, "Quartos vagos" e "Quartos ocupados" (cada uma com contador), em vez de um `Wrap` único misturado.

**Portal — ocupação de quarto:** os dois modais (`_StayDatesDialog` de datas + `_AddGuestDialog` de hóspede, aberto depois, separado) foram substituídos por um único formulário **na própria página** do quarto vago (nada de modal) — abaixo da informação do quarto: datas de check-in/check-out, depois a seção "Hóspede" com tipo+número de documento e um botão "Buscar". Encontrado → nome, telefone, e-mail, endereço e país são preenchidos automaticamente (ainda editáveis, com um aviso "Hóspede encontrado: Nome — revise se necessário"); não encontrado → aviso "Nenhum cadastro encontrado" e os campos ficam prontos pra um cadastro novo. Um botão só ("Registrar hóspede e iniciar estadia") cria a Stay e o Guest em sequência e mostra o código de acesso ao final — mesmo resultado de antes, só que num fluxo contínuo.

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web --release` limpos no portal, `tsc --noEmit` limpo na API. Ciclo ponta a ponta via curl contra servidor local (banco de produção), com 2 quartos/estadias/hóspedes de teste criados e removidos ao final: quarto 1 ocupado com hóspede novo (documento inédito) → lookup pelo mesmo documento encontra os dados corretos → quarto 2 ocupado reaproveitando esses dados (mesma pessoa, segunda estadia) → mapa mostra os 2 quartos corretamente como ocupados.

## Fix — redirect de login quebrado apontava pro localhost em produção

**Status: concluído e em produção.**

Motivação: usuário relatou que, depois de muito tempo sem usar o portal (token expirado) ou limpando os dados do navegador, em vez de cair na tela de login, o app tentava acessar uma URL localhost e dava erro de conexão.

**Causa raiz:** `apps/konekto_portal/lib/site_config.dart` define `siteLoginUrl` (a URL de `apps/konekto_site/login.html`, a única tela de login real do produto — o portal não tem formulário próprio, só recebe um token via `?token=` na URL) como `String.fromEnvironment('SITE_LOGIN_URL', defaultValue: 'http://localhost:8080/login.html')`. **Todo deploy de produção do portal nesta sessão** (múltiplas fases) usou o comando de build sem passar `--dart-define=SITE_LOGIN_URL=...` — igual já era feito pra `API_BASE_URL`/`GUEST_APP_URL`, mas essa flag específica nunca foi incluída. Resultado: toda vez que `RedirectToLoginPage` precisava redirecionar (sessão expirada, token ausente, ou revogado do lado do servidor), o navegador tentava ir pra `http://localhost:8080/login.html` — que não existe na máquina do usuário — em vez do login real.

**Fix:** inverteu-se o padrão de "falha insegura" (localhost) pra "falha segura" (produção) — `defaultValue` agora é `https://konekto-app.vercel.app/login.html` (confirmado como o domínio real de produção do `konekto_site` via `vercel project ls`, e como `login.html` já tem `API_BASE_URL`/`PORTAL_URL` de produção hardcoded corretamente). Um dev local que precise apontar pro `konekto_site` rodando na própria máquina agora precisa passar a flag explicitamente (inversão deliberada — builds de produção esquecendo a flag é o cenário mais provável e mais caro de errar).

**Checkpoint:** `flutter analyze`/`flutter test` limpos. Build de produção gerado com a flag explícita mesmo assim (defesa em profundidade) e confirmado via `grep` no bundle final: nenhuma ocorrência de `localhost:8080`, `konekto-app.vercel.app/login` presente no `main.dart.js` compilado.

## Fix — máscara de CPF/telefone e código de acesso não copiável

**Status: concluído e em produção.**

Motivação: usuário testou o novo fluxo de ocupação de quarto (Fase Quartos 2.1) e apontou dois problemas de UX: os campos de CPF/documento e telefone aceitavam só dígitos crus sem nenhuma formatação, e o campo com o código de acesso do hóspede (mostrado depois de registrar) não dava pra selecionar o texto pra copiar.

**Máscaras:** novo `lib/utils/input_formatters.dart` — `CpfInputFormatter` (formata `000.000.000-00` progressivamente, só aplicado quando `documentType == cpf`; passaporte/outro documento fica livre, sem formato fixo) e `BrazilPhoneInputFormatter` (formata `(00) 00000-0000` pra celular ou `(00) 0000-0000` pra fixo, conforme a quantidade de dígitos). Aplicados nos três lugares onde existe um formulário de hóspede: o formulário de ocupação de quarto (`rooms_page.dart`), `_AddGuestDialog` (adicionar hóspede a uma estadia já existente) e `_GuestEditDialog` (editar cadastro).

Detalhe técnico: `IntlPhoneField` define um `maxLength` interno baseado em contagem de DÍGITOS — como a máscara acrescenta parênteses/espaço/traço, o campo cortaria a digitação antes de caber o número inteiro. Precisou de `disableLengthCheck: true` em todo `IntlPhoneField` que ganhou a máscara. O valor mascarado nunca é gravado direto — sempre passa por `stripNonDigits()` antes de virar `phoneNumber`/`whatsappNumber` no payload da API (que já guarda telefone só em dígitos; CPF continua guardado COM pontuação, que já era a convenção existente). Cadastro pré-preenchido (edição, ou busca por documento no fluxo de ocupação) também é formatado antes de virar `initialValue`, já que `inputFormatters` só atua em edições, não no valor inicial.

**Código de acesso copiável:** novo `lib/widgets/copyable_code_box.dart` (`CopyableCodeBox`) — `SelectableText` (em vez de `Text` comum) + botão de copiar explícito. Substituído em todo lugar que mostra um código de acesso: diálogo de "hóspede registrado" em `rooms_page.dart` e `stay_detail_page.dart` (antes só texto puro), o mesmo diálogo em `guests_page.dart` (já tinha botão de copiar, ganhou o texto selecionável também) e a linha "Código de acesso" no cadastro completo em `guest_detail_page.dart` (antes um `_DetailLine` sem nenhuma forma de copiar).

**Checkpoint:** `flutter analyze`/`flutter test`/`flutter build web --release` limpos. Novo `test/utils/input_formatters_test.dart` (8 casos) — pegou um bug real durante o desenvolvimento: o `BrazilPhoneInputFormatter` fechava o parêntese do DDD errado num estado intermediário específico (2 dígitos digitados), corrigido antes do deploy.
