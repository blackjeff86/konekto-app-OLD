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

## Itens abertos (pendências conhecidas, não bloqueiam)

- **Imagem de item com URL externa não carrega no app do hóspede** (`TenantImage`, `apps/konekto_mobile/lib/widgets/tenant_image.dart`): criamos o widget que decide entre `Image.asset` (conteúdo semeado) e `Image.network` (itens novos do portal), mas testando com uma URL real (`fontagua.com.br`) a imagem não carregou — provavelmente CORS do host de origem, hotlink bloqueado, ou renderer CanvasKit do Flutter Web exigindo CORS pra decodificar a imagem em textura. Investigar depois: (1) testar com uma URL de imagem de um host que permite CORS/hotlink (ex: Unsplash, Cloudinary), (2) considerar um proxy de imagem no backend, ou (3) adicionar upload de imagem pro próprio `konekto_api`/storage em vez de depender de URL externa.
