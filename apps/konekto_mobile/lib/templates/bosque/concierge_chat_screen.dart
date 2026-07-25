import 'package:flutter/material.dart';
import 'package:konekto/templates/bosque/theme.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_bubble.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_input_bar.dart';

/// Adaptado de `bosque_concierge_chat/code.html` ("Chat with our Guide").
class BosqueConciergeChatScreen extends StatefulWidget {
  const BosqueConciergeChatScreen({super.key});

  @override
  State<BosqueConciergeChatScreen> createState() => _BosqueConciergeChatScreenState();
}

class _BosqueConciergeChatScreenState extends State<BosqueConciergeChatScreen> {
  final _controller = TextEditingController();
  final List<({bool isGuest, String text, String time})> _messages = [
    (isGuest: false, text: 'How can we make your forest stay more comfortable today?', time: '08:15 AM'),
    (isGuest: true, text: "I'm looking for a quiet spot for sunset yoga. Any suggestions near the river?", time: '08:20 AM'),
    (isGuest: false, text: "The Pebble Beach clearing is perfect. It's about a 10-minute walk east. I've sent the coordinates to your map!", time: '08:22 AM'),
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
    final theme = bosqueTheme;
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Chat with our Guide', style: theme.display(fontSize: 20, fontWeight: FontWeight.w600, color: colors.primary)),
                ],
              ),
            ),
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
                quickReplies: const ['Thank you', 'One moment', 'Call the lodge'],
                controller: _controller,
                onSend: _send,
                hintText: 'Message your guide...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
