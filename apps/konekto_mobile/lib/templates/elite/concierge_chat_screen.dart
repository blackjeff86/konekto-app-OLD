import 'package:flutter/material.dart';
import 'package:konekto/templates/elite/theme.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_bubble.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_input_bar.dart';

/// Adaptado de `lite_concierge_chat/code.html` — perfil do concierge
/// centralizado no topo (mais editorial/formal que os outros 3).
class EliteConciergeChatScreen extends StatefulWidget {
  const EliteConciergeChatScreen({super.key});

  @override
  State<EliteConciergeChatScreen> createState() => _EliteConciergeChatScreenState();
}

class _EliteConciergeChatScreenState extends State<EliteConciergeChatScreen> {
  final _controller = TextEditingController();
  final List<({bool isGuest, String text, String time})> _messages = [
    (isGuest: true, text: 'Good morning. Is there a car available for our winery tour this afternoon?', time: '10:45 AM'),
    (isGuest: false, text: 'Mr. Julian, your private chauffeur is ready for your departure to the vineyard. A vintage 1963 Bentley is awaiting you at the main portico.', time: '10:48 AM'),
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
    final theme = eliteTheme;
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(radius: 32, backgroundColor: colors.surfaceContainerHighest, child: Icon(Icons.support_agent, color: colors.primary, size: 28)),
            const SizedBox(height: 12),
            Text('Concierge Elite', style: theme.display(fontSize: 18, fontWeight: FontWeight.w400, color: colors.primary)),
            Text(
              'AVAILABLE TO ASSIST YOU',
              style: theme.body(fontSize: 10, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant).copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final message in _messages) ...[
                    GuestTemplateChatBubble(theme: theme, isGuest: message.isGuest, text: message.text, time: message.time),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GuestTemplateChatInputBar(
                theme: theme,
                quickReplies: const ['Thank you', 'One moment', 'Call instead'],
                controller: _controller,
                onSend: _send,
                hintText: 'Message the concierge...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
