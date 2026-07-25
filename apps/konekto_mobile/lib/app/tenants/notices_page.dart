import 'dart:async';

import 'package:flutter/material.dart';
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/messages_repository.dart';
import 'package:konekto/data/notices_repository.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/models/stay_message.dart';
import 'package:konekto/models/stay_notice.dart';
import 'package:konekto/theme/guest_app_theme.dart';

sealed class _ChatItem {
  DateTime get createdAt;
}

class _NoticeItem extends _ChatItem {
  final StayNotice notice;
  _NoticeItem(this.notice);
  @override
  DateTime get createdAt => notice.createdAt;
}

class _MessageItem extends _ChatItem {
  final StayMessage message;
  _MessageItem(this.message);
  @override
  DateTime get createdAt => message.createdAt;
}

/// Avisos da recepção + chat com o hóspede — histórico de avisos antigos
/// (só leitura, dado legado) mesclado por data com o chat de verdade, que
/// permite o hóspede responder.
class NoticesPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final GuestAppTheme theme;

  const NoticesPage({super.key, required this.tenantConfig, required this.theme});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final NoticesRepository _noticesRepository = NoticesRepository();
  final MessagesRepository _messagesRepository = MessagesRepository();
  final _messageController = TextEditingController();

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  List<_ChatItem> _items = const [];

  GuestAppTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = await _guestClaimRepository.getStoredToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.sessionNotFound;
        _isLoading = false;
      });
      return;
    }
    try {
      final results = await Future.wait([_noticesRepository.getNotices(token: token), _messagesRepository.getMessages(token: token)]);
      final notices = results[0] as List<StayNotice>;
      final messages = results[1] as List<StayMessage>;
      final items = <_ChatItem>[...notices.map(_NoticeItem.new), ...messages.map(_MessageItem.new)]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (!mounted) return;
      setState(() {
        _items = items;
        _errorMessage = null;
      });
      unawaited(_messagesRepository.markRead(token: token));
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final token = await _guestClaimRepository.getStoredToken();
    if (token == null) return;

    setState(() => _isSending = true);
    try {
      await _messagesRepository.sendMessage(token: token, message: text);
      _messageController.clear();
      await _load();
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(child: Text(l10n.noticesTitle, style: theme.headline(fontSize: 22))),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _items.isEmpty
                      ? Center(child: Text(_errorMessage!, textAlign: TextAlign.center, style: theme.body(color: theme.mutedColor)))
                      : _items.isEmpty
                          ? Center(child: Text(l10n.chatEmpty, style: theme.body(color: theme.mutedColor)))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[_items.length - 1 - index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: switch (item) {
                                      _NoticeItem() => _NoticeBubble(notice: item.notice, theme: theme, formatDate: _formatDateTime),
                                      _MessageItem() => _MessageBubble(message: item.message, theme: theme, formatDate: _formatDateTime),
                                    },
                                  );
                                },
                              ),
                            ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      style: theme.body(),
                      decoration: InputDecoration(
                        hintText: l10n.chatHintText,
                        hintStyle: theme.body(color: theme.mutedColor),
                        filled: true,
                        fillColor: theme.cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(theme.tokens.pillRadius),
                          borderSide: BorderSide(color: theme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(theme.tokens.pillRadius),
                          borderSide: BorderSide(color: theme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(theme.tokens.pillRadius),
                          borderSide: BorderSide(color: theme.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accent),
                    child: IconButton(
                      onPressed: _isSending ? null : _send,
                      icon: _isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeBubble extends StatelessWidget {
  final StayNotice notice;
  final GuestAppTheme theme;
  final String Function(DateTime) formatDate;

  const _NoticeBubble({required this.notice, required this.theme, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(color: theme.accentSoft, borderRadius: BorderRadius.circular(theme.tokens.cardRadius)),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined, size: 14, color: theme.accent),
                const SizedBox(width: 6),
                Flexible(child: Text(notice.message, textAlign: TextAlign.center, style: theme.body(fontSize: 13, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 4),
            Text(formatDate(notice.createdAt), style: theme.body(fontSize: 11, color: theme.mutedColor)),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final StayMessage message;
  final GuestAppTheme theme;
  final String Function(DateTime) formatDate;

  const _MessageBubble({required this.message, required this.theme, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isStaff = message.senderType == MessageSender.staff;
    return Row(
      mainAxisAlignment: isStaff ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(
                isStaff ? l10n.chatReception : (message.guestFirstName ?? l10n.chatYou),
                style: theme.body(fontSize: 11, fontWeight: FontWeight.w600, color: theme.mutedColor),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isStaff ? theme.cardBg : theme.accent,
                  border: isStaff ? Border.all(color: theme.borderColor) : null,
                  borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
                ),
                child: Text(message.body, style: theme.body(color: isStaff ? theme.textColor : Colors.white)),
              ),
              const SizedBox(height: 2),
              Text(formatDate(message.createdAt), style: theme.body(fontSize: 10.5, color: theme.mutedColor)),
            ],
          ),
        ),
      ],
    );
  }
}
