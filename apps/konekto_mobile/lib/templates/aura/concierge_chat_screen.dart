import 'package:flutter/material.dart';
import 'package:konekto/templates/aura/theme.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_bubble.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_input_bar.dart';

/// Adaptado de `aura_concierge_chat/code.html`.
class AuraConciergeChatScreen extends StatefulWidget {
  const AuraConciergeChatScreen({super.key});

  @override
  State<AuraConciergeChatScreen> createState() => _AuraConciergeChatScreenState();
}

class _AuraConciergeChatScreenState extends State<AuraConciergeChatScreen> {
  final _controller = TextEditingController();
  final List<({bool isGuest, String text, String time})> _messages = [
    (isGuest: false, text: 'Welcome back, Mr. Julian. How can we assist you at the Aura today?', time: '09:30 AM'),
    (isGuest: true, text: "Good morning! I'd like to inquire about the check-out process. Is there a possibility for a late departure?", time: '09:32 AM'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add((isGuest: true, text: text, time: 'now'));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = auraTheme;
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final message in _messages) ...[
                    GuestTemplateChatBubble(theme: theme, isGuest: message.isGuest, text: message.text, time: message.time),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GuestTemplateChatInputBar(
                theme: theme,
                quickReplies: const ['Need more towels', 'Wake up call', 'Late check-out request'],
                controller: _controller,
                onSend: _send,
                hintText: 'Message Concierge...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
