# Spec: Portal do Hotel — Fase 5 (Hóspedes, Pedidos, Configurações)

## Objective

O portal do hotel (`apps/konekto_portal`) hoje só tem login funcional e um dashboard-esqueleto: as três seções da navegação (Hóspedes, Pedidos, Configurações) são cartões "Em breve" sem lógica real por trás. Esta fase entrega as três funcionalidades de verdade, permitindo que o staff do hotel (gerente/recepção) opere o dia a dia sem depender de um desenvolvedor.

**Usuários**: staff de hotel (papéis `gerente` e `recepcao`, já autenticados via JWT).

**User stories**:
- Como recepcionista, quero gerar um código de acesso individual pra um hóspede (nome + quarto) e revogar esse acesso quando ele fizer check-out, pra controlar quem tem acesso ao app do hotel.
- Como hóspede, quero digitar/escanear meu código individual no app e entrar direto na experiência do meu hotel — sem cadastro, sem senha.
- Como recepcionista, quero ver os pedidos de room service/spa/restaurante/passeios que os hóspedes fizerem, e marcar cada um como em andamento/concluído, pra não perder nenhum pedido.
- Como hóspede, quero que meu pedido (room service, reserva de spa, etc.) realmente chegue na recepção, não apenas mostre uma mensagem de confirmação falsa.
- Como gerente, quero editar a marca do meu hotel (nome, logo, cor) e habilitar/desabilitar categorias de serviço, sem precisar pedir pra um desenvolvedor mexer em JSON.

**Sucesso** = as três seções do portal deixam de ser "Em breve" e viram telas funcionais, com dados reais persistidos no Postgres (Neon) e refletidos de volta no app do hóspede.

## Tech Stack

- Backend: Next.js 16 (App Router, só rotas de API) + Prisma 7 + Neon Postgres — `apps/konekto_api`
- Portal: Flutter Web — `apps/konekto_portal`
- App do hóspede: Flutter (mobile + web) — `apps/konekto_mobile`
- Auth: JWT (`jose`) — já existe pro staff; esta fase adiciona um JWT equivalente pro hóspede (sem senha — resolve de um código de acesso)

## Ordem de construção (confirmada com o usuário)

1. **Configurações** — mais independente, não muda o app do hóspede, menor risco.
2. **Hóspedes** — introduz a tabela `guests` e a troca do código único-por-hotel pra código individual-por-hóspede.
3. **Pedidos** — depende de (2): só faz sentido um pedido "pertencer" a alguém depois que existe identidade real de hóspede.

Cada uma dessas é tratada como uma sub-fase com seu próprio ciclo Plan → Tasks → Implement, não uma implementação monolítica.

## Commands

```
# Backend (apps/konekto_api)
Dev:      npm run dev
Build:    npm run build
Lint:     npm run lint
Migrate:  npx prisma migrate dev --name <nome>
Studio:   npm run prisma:studio
Seed:     npm run db:seed

# Portal (apps/konekto_portal)
Dev:      flutter run -d chrome --web-port=5050 --dart-define=API_BASE_URL=http://localhost:3000
Analyze:  flutter analyze
Test:     flutter test

# App do hóspede (apps/konekto_mobile)
Dev:      flutter run -d chrome --dart-define=USE_API=true --dart-define=API_BASE_URL=http://localhost:3000
Analyze:  flutter analyze
Test:     flutter test
```

## Project Structure (o que muda)

```
apps/konekto_api/
  prisma/schema.prisma        → novos models: Guest, Order (+ enums GuestStatus, OrderStatus, OrderType)
  app/api/hotels/[hotelId]/guests/            → CRUD de hóspedes (staff)
  app/api/hotels/[hotelId]/orders/            → listagem/atualização de pedidos (staff)
  app/api/guest/claim/                        → resolve código de acesso → JWT de hóspede (público)
  app/api/orders/                             → criação de pedido (hóspede autenticado)
  app/api/hotels/[hotelId]/content/[docName]/ → já existe (leitura); esta fase adiciona PATCH (gerente only)
  app/api/hotels/[hotelId]/                   → já existe (leitura); esta fase adiciona PATCH pra branding (gerente only)
  app/api/staff-invites/                      → gerente cria convite; nova conta consome o convite
  lib/guest-auth.ts                           → assinatura/verificação do JWT de hóspede (paralelo a lib/jwt.ts)

apps/konekto_portal/
  lib/features/guests/          → tela Hóspedes (lista, criar, revogar)
  lib/features/orders/          → tela Pedidos (lista, mudar status, polling)
  lib/features/settings/        → tela Configurações (marca + editor de catálogo por categoria)
  lib/features/staff/           → gerente gera convites de recepção

apps/konekto_mobile/
  lib/app/navigation/          → troca o código único do hotel pelo código individual do hóspede na tela de acesso
  lib/app/tenants/*_detail_page.dart  → troca o SnackBar fake por um POST real em /api/orders
```

## Code Style

Segue os padrões já estabelecidos nesta sessão — não introduz nada novo:

```dart
// Repositório com interface abstrata + implementação HTTP (mesmo padrão de
// apps/konekto_mobile/lib/data/http_tenant_repository.dart)
abstract class GuestsRepository {
  Future<List<Guest>> listGuests(String hotelId);
  Future<Guest> createGuest({required String hotelId, required String name, required String roomNumber});
  Future<void> revokeGuest(String hotelId, String guestId);
}
```

```ts
// Rota de API — mesmo formato de apps/konekto_api/app/api/auth/login/route.ts:
// zod pra validar body, prisma pra persistir, NextResponse.json pra responder
export async function POST(request: NextRequest) {
  const parsed = createGuestSchema.safeParse(await request.json().catch(() => null))
  if (!parsed.success) return NextResponse.json({ error: 'invalid_request' }, { status: 400 })
  // ...
}
```

## Testing Strategy

- **API** (`apps/konekto_api`): `curl` manual contra cada rota nova (mesmo processo usado nesta sessão pra `/api/auth/login`, `/api/auth/me`) — sem framework de teste automatizado configurado no backend ainda; não introduzir um novo nesta fase (fora de escopo).
- **Portal** (`apps/konekto_portal`): `flutter analyze` + `flutter test` limpos após cada sub-fase, como já vem sendo feito. Smoke test por tela nova (renderiza sem erro), seguindo `test/widget_test.dart` existente.
- **App do hóspede**: `flutter analyze` + `flutter test` limpos. Testar manualmente o fluxo de claim de código (`flutter run -d chrome`).
- Verificação end-to-end manual entre as três partes (portal cria hóspede → hóspede reivindica código no app → hóspede faz pedido → portal vê o pedido) é o critério de aceite real, não só testes unitários.

## Boundaries

- **Sempre fazer**: `flutter analyze`/`flutter test` limpos antes de considerar uma sub-fase concluída; seguir o padrão repositório+JWT já estabelecido; manter `role: gerente` como exigência pra rotas de Configurações.
- **Perguntar antes**: qualquer mudança de schema Prisma que não esteja neste spec; adicionar nova dependência (ex: biblioteca de upload de imagem pro logo); mudar o comportamento do código único-por-hotel existente além do que este spec já define.
- **Nunca fazer**: expor rotas de staff (guests/orders/config) sem checar o JWT e o papel (`role`); deixar o código de acesso do hóspede em texto legível em logs; remover o código único-por-hotel antes de Hóspedes (2) estar completo e testado (evita quebrar o acesso atual no meio do caminho).

## Success Criteria

- [ ] **Configurações**: gerente consegue editar nome do hotel, logo (URL) e cor primária, e adicionar/editar/remover itens de room service, spa, restaurantes, eventos e passeios pelo portal — mudanças aparecem no app do hóspede sem rebuild.
- [ ] **Hóspedes**: recepção consegue criar um hóspede (nome + quarto), receber um código individual, ver a lista de hóspedes ativos, e revogar acesso — e o hóspede revogado deixa de conseguir entrar no app.
- [ ] **Pedidos**: um pedido feito no app do hóspede (qualquer um dos 4 tipos) aparece na lista de Pedidos do portal em até N segundos (polling), com nome do hóspede e quarto corretos, e a recepção consegue mudar o status.
- [ ] `recepcao` não consegue acessar/alterar Configurações (só `gerente` pode) nem convidar novo staff.
- [ ] Um `gerente` consegue gerar um convite, e uma nova conta se cadastrando com esse convite vira `recepcao` daquele hotel automaticamente.

## Revisão de arquitetura (pós-Fase 3, antes da Fase 4)

Durante a Fase 3 (Room Service), ficou claro um problema de fundo: os 5 tipos de serviço (Room Service, Spa, Restaurantes, Eventos, Passeios) eram fixos no código — cada um com schema, tela e rota hardcoded. Isso significa que um hotel nunca poderia oferecer um serviço diferente desses 5 (ex: aluguel de bicicleta, lavanderia). **Decisão: substituir por um modelo genérico `Service` → `ServiceItem`**, onde o hotel cria seus próprios serviços (nome, ícone, descrição) e adiciona itens a cada um — sem tipos fixos no código.

Isso **substitui** o plano original da Fase 4 (repetir o editor de Room Service 4 vezes, um por tipo fixo) por um único editor genérico. A Fase 3 (Room Service) não foi desperdiçada — o padrão de UI (lista + formulário de item) se mantém, só a camada de dados vira genérica.

**Caso especial resolvido**: Restaurantes hoje é "uma lista de restaurantes, cada um com seu cardápio" (2 níveis) — diferente dos outros (1 nível: serviço → itens). Decisão: cada restaurante vira seu próprio `Service` (ex: "Le Maré", "La Piazza"), cada um aparecendo como um card independente pro hóspede, em vez de um card único "Restaurantes" levando a uma lista.

## Decisões (confirmadas com o usuário)

1. **Configurações**: editor completo de cardápio/catálogo item por item (não só marca básica) — inclui adicionar/editar/remover itens de room service, spa, restaurantes, eventos e passeios, além de nome/logo/cor do hotel.
2. **Pedidos**: os 4 tipos entram juntos nesta fase — room service, spa, restaurante e passeios passam a gravar pedidos reais simultaneamente (não faseado por tipo).
3. **Notificação de pedido novo**: tempo real. Mecanismo concreto: **polling no portal** (o Flutter Web faz `GET /api/hotels/:hotelId/orders` a cada N segundos enquanto a aba de Pedidos está aberta) — não WebSocket/push. Justificativa técnica: a API roda em funções serverless da Vercel, que não sustentam conexões persistentes de forma simples/gratuita; polling é o mecanismo mais simples que ainda entrega "tempo real" pro caso de uso (recepção olhando a tela). Web Push (som/notificação do navegador mesmo com a aba em background) fica fora de escopo desta fase — revisar se polling for insuficiente na prática.
4. **Convite de `recepcao`**: incluído nesta fase — fluxo do plano original (`gerente` cria um convite → nova conta se cadastra com o código do convite → vira `recepcao` daquele hotel), sem Cloud Functions.

Dado o escopo bem maior que o mínimo original, a fase de Plan (próxima etapa) vai quebrar isso em sub-entregas sequenciais menores dentro de cada seção — ver `tasks/plan.md` quando gerado.
