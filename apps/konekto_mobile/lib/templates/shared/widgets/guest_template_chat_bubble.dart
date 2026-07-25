import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Balão de mensagem (recepção à esquerda, hóspede à direita) — igual nos
/// 4 templates novos, só cor/raio mudam via [theme]. Conversa é dado de
/// demonstração (ver telas de cada template); a Fase 4 troca isso pelo
/// `MessagesRepository` real.
class GuestTemplateChatBubble extends StatelessWidget {
  final GuestTemplateTheme theme;
  final bool isGuest;
  final String text;
  final String time;

  const GuestTemplateChatBubble({super.key, required this.theme, required this.isGuest, required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Align(
      alignment: isGuest ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isGuest ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isGuest ? colors.primary : colors.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(theme.radiusLg),
                  topRight: Radius.circular(theme.radiusLg),
                  bottomLeft: Radius.circular(isGuest ? theme.radiusLg : 4),
                  bottomRight: Radius.circular(isGuest ? 4 : theme.radiusLg),
                ),
              ),
              child: Text(text, style: theme.body(color: isGuest ? colors.onPrimary : colors.onSurface)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(time, style: theme.body(fontSize: 10, color: colors.outline)),
          ),
        ],
      ),
    );
  }
}
