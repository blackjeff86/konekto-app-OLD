import 'dart:async';
import 'package:flutter/material.dart';
import 'package:konekto_portal/auth/auth_repository.dart';
import 'package:konekto_portal/auth/staff_session.dart';
import 'package:konekto_portal/data/support_repository.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Conversa direta do hotel com a equipe do Konekto — diferente do chat
/// hóspede<->recepção (aba Quartos), aqui é sempre o hotel falando com a
/// Konekto (suporte, dúvida, problema com alguma funcionalidade).
class SupportPage extends StatefulWidget {
  final StaffSession session;
  final AuthRepository authRepository;

  const SupportPage({
    super.key,
    required this.session,
    required this.authRepository,
  });

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _repository = SupportRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  List<SupportMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Sessão expirada — saia e entre novamente.';
        _isLoading = false;
      });
      return;
    }
    try {
      final messages = await _repository.listMessages(
        hotelId: widget.session.hotelId,
        token: token,
      );
      setState(() => _messages = messages);
      unawaited(_repository.markMessagesRead(hotelId: widget.session.hotelId, token: token));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final token = await widget.authRepository.getStoredToken();
    if (token == null) {
      setState(() => _errorMessage = 'Sessão expirada — saia e entre novamente.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      await _repository.sendMessage(hotelId: widget.session.hotelId, token: token, message: message);
      _messageController.clear();
      await _load();
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Suporte', style: KonektoBrand.display(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          'Fale direto com a equipe do Konekto — dúvidas, problemas ou pedidos de ajuda.',
          style: KonektoBrand.body(fontSize: 12.5),
        ),
        const SizedBox(height: 20),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x1ADC2626),
              border: Border.all(color: const Color(0x4DDC2626)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _errorMessage!,
              style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KonektoBrand.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KonektoBrand.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: KonektoBrand.gold))
                      : _messages.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma mensagem ainda — envie a primeira abaixo.',
                                style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.slate),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                            ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        style: KonektoBrand.body(fontSize: 14, color: KonektoBrand.cream),
                        decoration: InputDecoration(
                          hintText: 'Escreva sua mensagem...',
                          hintStyle: KonektoBrand.body(fontSize: 13, color: KonektoBrand.slate),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.03),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: KonektoBrand.borderStrong, width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: KonektoBrand.gold, width: 1.6),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KonektoBrand.gold,
                          foregroundColor: KonektoBrand.ink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: KonektoBrand.ink),
                              )
                            : const Icon(Icons.send, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isFromPlatform = message.isFromPlatform;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isFromPlatform ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isFromPlatform ? Colors.white.withValues(alpha: 0.04) : KonektoBrand.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFromPlatform ? 'Konekto' : 'Você',
                    style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w700, color: KonektoBrand.goldLight),
                  ),
                  const SizedBox(height: 2),
                  Text(message.body, style: KonektoBrand.body(fontSize: 13.5, color: KonektoBrand.cream)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
