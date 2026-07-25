import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Chips de sugestão rápida + campo de texto com botão de enviar — igual
/// nos 4 templates novos.
class GuestTemplateChatInputBar extends StatelessWidget {
  final GuestTemplateTheme theme;
  final List<String> quickReplies;
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;

  const GuestTemplateChatInputBar({
    super.key,
    required this.theme,
    required this.quickReplies,
    required this.controller,
    required this.onSend,
    this.hintText = 'Message...',
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickReplies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(theme.radiusXl * 2),
              ),
              child: Text(quickReplies[index], style: theme.labelCaps(color: colors.onSurfaceVariant)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(left: 18, right: 6),
          decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(theme.radiusXl * 2)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: hintText, border: InputBorder.none),
                  style: theme.body(color: colors.onSurface),
                ),
              ),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary),
                  child: Icon(Icons.arrow_upward, color: colors.onPrimary, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
