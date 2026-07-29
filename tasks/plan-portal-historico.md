# Implementation Plan: Portal do Hotel — Configurações (+ Convite de Staff)

> Arquivo preservado como histórico em 29 de julho de 2026, quando `tasks/plan.md`
> passou a ser usado pela frente de migração do template Aura para o guest app
> TypeScript.

> **Nota histórica**: escrito quando o portal do hotel era o app Flutter
> `apps/konekto_portal`. Esse app foi descontinuado e removido do repositório — o
> portal em produção hoje é `apps/sevvn_portal_next` (Next.js). Todas as
> referências a `apps/konekto_portal` abaixo (e a `apps/sevvn_admin` nas fases mais
> recentes, se houver) registram fielmente o que foi construído em cada momento; não
> são instruções válidas pro código atual.

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
- [ ] **Task 2: `PATCH /api/hotels/:hotelId` (branding)**
- [ ] **Task 3: `PATCH /api/hotels/:hotelId/content/:docName` (catálogo genérico)**

### Phase 2: Branding

- [ ] **Task 4: Repositório de branding no portal**
- [ ] **Task 5: Tela de Configurações — aba Marca**

### Phase 3: Catálogo — Room Service (estabelece o padrão)

- [ ] **Task 6: Repositório + modelo de catálogo (Room Service)**
- [ ] **Task 7: Tela de edição de Room Service**

### Phase 4 (Revisada): Serviços Dinâmicos

- [ ] **Task 8+: Serviços dinâmicos / seed / rotas / portal / app do hóspede**

### Phase 5: Convite de staff

- [ ] **Task 12+: convite de staff ponta a ponta**
