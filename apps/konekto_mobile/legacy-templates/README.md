# Templates legados do app do hóspede

Os 5 templates visuais usados antes do White Label (Aura/Bosque/Elite/Pulse/Horizon,
em `lib/templates/`): **Amara Bay**, **Verde Pousada**, **Casa Marechal**, **Konekto
Clássico** e **Konekto Noturno**.

## Status

- **Fora de `lib/`** — não compila, não é buildado, não é acessível por nenhum hotel.
- **Preservado pra referência/retrabalho futuro** — se algum dia fizer sentido
  atualizar um destes e colocar de volta em produção, mova a pasta relevante de
  volta pra dentro de `lib/`, reconecte as importações (grep por
  `package:konekto/templates/` nos arquivos movidos) e registre de novo no
  `TenantHomeBody` (`lib/app/tenants/tenant_home_page.dart`).
- Konekto Clássico e Konekto Noturno reaproveitavam os widgets de Amara Bay/Verde
  Pousada (ver `template_registry.dart` aqui dentro) — não têm arquivo de Home
  próprio.

## Estrutura

```
legacy-templates/
  lib/
    theme/
      guest_infra.dart          — GuestInfra enum + os 5 tokens fixos (cor/fonte/raio)
    templates/
      template_registry.dart    — GuestInfra → widget de Home
      amara_bay/home_screen.dart
      verde_pousada/home_screen.dart
      casa_marechal/home_screen.dart
      shared/
        guest_home_content_params.dart
        widgets/
          expandable_card.dart
          header_icon_button.dart
          image_carousel.dart
          notification_count_badge.dart
          tenant_logo.dart
```

## Por que foram arquivados

O app do hóspede migrou pra um sistema de White Label: 5 templates novos
(Aura/Bosque/Elite/Pulse/Horizon) selecionáveis por hotel via plano comercial
(Essential/Premium/Enterprise), com o mecanismo de feature flags. Os 5 templates
antigos aqui não fazem mais parte do catálogo — nenhum hotel real pode escolhê-los,
e o app não os renderiza.

As telas compartilhadas (Serviços, Reservas, Perfil, Avisos, Meus Pedidos, Info do
Hotel, Conta da estadia) **não foram arquivadas** — elas nunca foram exclusivas de
nenhum template, e hoje usam um tema único e neutro (`GuestAppTheme`, em
`lib/theme/guest_app_theme.dart`), independente de qual dos 5 templates novos o
hotel escolheu pra Home.
