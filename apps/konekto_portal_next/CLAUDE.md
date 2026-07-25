@AGENTS.md

## Convenções de layout (telas do portal)

- **Nunca** aplique `max-w-[...]` + `mx-auto` pra limitar a largura do conteúdo de uma
  página dentro do shell autenticado (`app/(portal)/**/page.tsx`), **incluindo as de
  `/settings/*`**. O layout (`app/(portal)/layout.tsx`) já dá `px-10 py-10` — a página
  deve preencher esse espaço inteiro (grids, cards, listas, formulários), não criar uma
  coluna fixa centralizada com sobra de espaço vazio nas laterais em telas largas.
  Já corrigido em `/guests/[guestId]`, `/customers`, `/customers/[documentNumber]`,
  `/rooms/[roomId]`, `/settings/branding`, `/settings/integrations`,
  `/settings/payments`, `/settings/services/[serviceId]` e `/settings/staff` — aplique
  o mesmo em qualquer tela nova ou refeita.
- Exceção real (não é sobre largura de página): dentro de `/settings/appearance`, o
  card do seletor de template tem `max-w-[520px]` porque fica lado a lado com a prévia
  do template numa linha `flex-wrap` — a largura da PÁGINA já é cheia, só esse card
  específico tem tamanho controlado de propósito. Não confundir os dois casos.
