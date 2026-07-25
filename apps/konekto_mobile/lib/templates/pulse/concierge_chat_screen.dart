import 'package:flutter/material.dart';
import 'package:konekto/templates/pulse/theme.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_bubble.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_input_bar.dart';

/// Adaptado de `pulse_concierge_chat/code.html` ("AI Concierge · Pulse
/// Premium").
class PulseConciergeChatScreen extends StatefulWidget {
  const PulseConciergeChatScreen({super.key});

  @override
  State<PulseConciergeChatScreen> createState() => _PulseConciergeChatScreenState();
}

class _PulseConciergeChatScreenState extends State<PulseConciergeChatScreen> {
  final _controller = TextEditingController();
  final List<({bool isGuest, String text, String time})> _messages = [
    (isGuest: false, text: "Good evening. I've reserved your table at the rooftop restaurant for 8 PM. Anything else you need?", time: '19:02'),
    (isGuest: true, text: 'Perfect. Can you also arrange a car for tomorrow morning?', time: '19:05'),
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
    final theme = pulseTheme;
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
                  Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('AI Concierge', style: theme.display(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
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
                quickReplies: const ['Yes, please', 'Not now', 'Call reception'],
                controller: _controller,
                onSend: _send,
                hintText: 'Ask the concierge...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
