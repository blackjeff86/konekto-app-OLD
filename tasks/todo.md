# Todo: Portal do Hotel — Configurações (+ Convite de Staff)

Plano completo em `tasks/plan.md`. Spec em `specs/portal-fase5-hospedes-pedidos-config.md`.

## Phase 1: Foundation
- [x] Task 1: Guarda de papel compartilhada (`requireStaffRole`)
- [x] Task 2: `PATCH /api/hotels/:hotelId` (branding)
- [x] Task 3: `PATCH /api/hotels/:hotelId/content/:docName` (catálogo genérico)
- [x] **Checkpoint:** curl validando autorização + build limpo + revisar com usuário

## Phase 2: Branding
- [x] Task 4: Repositório de branding no portal
- [x] Task 5: Tela de Configurações — aba Marca
- [x] Bug encontrado e corrigido: `Access-Control-Allow-Methods` não incluía `PATCH` (proxy.ts)
- [x] **Checkpoint:** fluxo ponta a ponta (portal → app do hóspede) confirmado pelo usuário

## Phase 3: Catálogo — Room Service (padrão)
- [x] Task 6: Repositório + modelo (Room Service)
- [x] Task 7: Tela de edição de Room Service
- [x] Criado `TenantImage` (asset local vs URL de rede) — ver item aberto no plan.md sobre imagem externa não carregando
- [x] **Checkpoint:** padrão validado (adicionar/editar/remover item funciona ponta a ponta; imagem externa é um item aberto, não bloqueia)

## Phase 4 (REVISADA): Serviços Dinâmicos (substitui o plano fixo original)
### A: Modelo + migração
- [x] Task 8: Models `Service`/`ServiceItem` + migration
- [x] Task 9: Atualizar seed.ts (migra os 5 tipos, restaurantes → N services)
- [x] **Checkpoint A** — seed populou 8 services / 41 items (hotel_1: room-service, spa, 3 restaurantes como services independentes, eventos, passeios; hotel_2: room-service); `npm run build` limpo
### B: Rotas de API
- [x] Task 10: Leitura pública (`GET /services`, `GET /services/:id`)
- [x] Task 11: Escrita de serviço (POST/PATCH/DELETE, gerente only)
- [x] Task 12: Escrita de item (POST/PATCH/DELETE, gerente only)
- [x] **Checkpoint B** — curl 401/403/200 validado; build limpo; serviço novo "Aluguel de Bicicleta" testado ponta a ponta
### C: Portal
- [x] Task 13: ServiceRepository + modelos Dart
- [x] Task 14: Tela "Serviços" (lista + criar)
- [x] Task 15: Tela de gestão de itens
- [x] Task 16: Remover código supersedido da Fase 3
- [x] **Checkpoint C** — analyze/test/build web limpos; CRUD validado via curl (mesmo contrato); navegação revisada por código (sem browser automation disponível)
### D: App do hóspede
- [x] Task 17: ServiceRepository (leitura) — métodos adicionados na `TenantRepository` existente
- [x] Task 18: Lista de serviços genérica
- [x] Task 19+20: Telas genéricas de itens + detalhe
- [x] Task 21: Remover as 10 telas antigas + métodos supersedidos da interface
- [x] **Checkpoint D** — analyze/test/build web (2 modos) limpos; dados confirmados via curl contra a API viva
### E: Verificação final
- [~] Criar serviço 100% novo (ex: Aluguel de Bicicleta) e confirmar ponta a ponta — criado/editado/removido via curl no Checkpoint B (Fase B), confirmando que a API trata qualquer serviço novo sem código específico. Falta a confirmação visual no app do hóspede rodando de verdade (sem ferramenta de browser automation nesta sessão) — pendente de um teste manual do usuário.

## Phase 5: Convite de staff
- [x] Task 12: Model `StaffInvite` + migration
- [x] Task 13: `POST /api/staff-invites` (gerente cria)
- [x] Task 14: `POST /api/staff-invites/:code/consume` (novo staff se cadastra)
- [x] Task 15: Tela "Gerar convite" (gerente) — 3ª seção "Equipe" em Configurações
- [x] Task 16: Tela de cadastro com convite — `?invite=<code>` roteado antes do StaffGate
- [x] **Checkpoint:** fluxo ponta a ponta validado via curl (criar→consumir→login com role correto→reuso rejeitado); analyze/test/build web limpos. Falta clique manual no Chrome (sem browser automation) — pendente de confirmação do usuário antes de encerrar a sub-entrega Configurações.
