# Pilot Validation: Aura Guest Essential

Data de referência: 29/07/2026

## Objetivo

Validar que o `apps/sevvn_guest_next` já pode operar como casca TypeScript do pacote Essential, consumindo apenas dados reais do hotel autenticado.

## Caminho mínimo do piloto

1. Entrar com um código de acesso válido do hóspede.
2. Confirmar na Home:
   - nome do hotel;
   - quarto;
   - Wi-Fi;
   - datas de check-in e check-out.
3. Abrir `Serviços` e validar:
   - agrupamentos;
   - banners/imagens quando existirem;
   - ausência de serviços fantasma.
4. Abrir um serviço operacional:
   - `room_service` para pedido;
   - `restaurant` para reserva;
   - `concierge` para mensagens.
5. Confirmar em `Reservas` que o pedido/reserva apareceu para a estadia autenticada.
6. Abrir `Mensagens` e enviar uma conversa real com a recepção.
7. Abrir `Notificações` e confirmar leitura dos notices reais da estadia.
8. Abrir `Perfil` e confirmar que os dados exibidos são do hóspede autenticado.

## Status esperado por superfície

- `Home`: ao vivo
- `Serviços`: ao vivo
- `Service detail / room service`: ao vivo
- `Reservas`: ao vivo
- `Mensagens / concierge`: ao vivo quando o módulo estiver habilitado
- `Notificações básicas`: ao vivo quando o módulo estiver habilitado
- `Perfil`: ao vivo
- `Wallet / loyalty / extras premium`: em breve

## Regras de aceite

- O hotel nunca pode ser trocado manualmente no app.
- O app não deve navegar para superfície inexistente como se estivesse pronta.
- Tudo que não estiver operacional precisa aparecer como `em breve` ou ficar efetivamente bloqueado por módulo.
