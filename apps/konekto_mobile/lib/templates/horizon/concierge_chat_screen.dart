import 'package:flutter/material.dart';
import 'package:konekto/templates/horizon/theme.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_bubble.dart';
import 'package:konekto/templates/shared/widgets/guest_template_chat_input_bar.dart';

/// Adaptado de `horizon_concierge_chat/code.html` ("Maria - Your Host").
class HorizonConciergeChatScreen extends StatefulWidget {
  const HorizonConciergeChatScreen({super.key});

  @override
  State<HorizonConciergeChatScreen> createState() => _HorizonConciergeChatScreenState();
}

class _HorizonConciergeChatScreenState extends State<HorizonConciergeChatScreen> {
  final _controller = TextEditingController();
  final List<({bool isGuest, String text, String time})> _messages = [
    (isGuest: false, text: 'Good morning, Mr. Julian! Your private transfer to the Blue Lagoon is scheduled for 10:00 AM. Would you like us to pack a beach hamper for you?', time: '08:42 AM'),
    (isGuest: true, text: "That sounds lovely, Maria. What's included in the hamper?", time: '08:44 AM'),
    (isGuest: false, text: "Our 'Azure Picnic' features organic seasonal fruits, artisanal sandwiches, chilled sparkling water, and our signature lemon-thyme shortbread.", time: '08:45 AM'),
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
    final theme = horizonTheme;
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
                  CircleAvatar(radius: 18, backgroundColor: colors.primaryContainer.withValues(alpha: 0.3), child: Icon(Icons.person, color: colors.primary, size: 18)),
                  const SizedBox(width: 10),
                  Text('Maria — Your Host', style: theme.display(fontSize: 17, fontWeight: FontWeight.w600, color: colors.onSurface)),
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
                quickReplies: const ['Yes, please!', 'Maybe later', 'Call me'],
                controller: _controller,
                onSend: _send,
                hintText: 'Message your host...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
