import 'package:flutter/material.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Pílula vermelha com a quantidade de notificações (mensagens da recepção
/// não lidas + pedidos com status não visto) — "9+" acima de 9 pra não
/// estourar o layout do sino. Igual em todos os templates.
class NotificationCountBadge extends StatelessWidget {
  final int count;
  final GuestAppTheme theme;

  const NotificationCountBadge({super.key, required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: count > 9 ? BorderRadius.circular(8) : null,
        color: Colors.red.shade600,
        border: Border.all(color: theme.bg, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, height: 1),
      ),
    );
  }
}
