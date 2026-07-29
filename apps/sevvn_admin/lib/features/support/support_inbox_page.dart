import 'package:flutter/material.dart';
import 'package:sevvn_admin/auth/auth_repository.dart';
import 'package:sevvn_admin/data/admin_support_repository.dart';
import 'package:sevvn_admin/features/clients/client_detail_page.dart';
import 'package:sevvn_admin/theme/konekto_brand.dart';

/// Visão cross-hotel das conversas de suporte, ordenada por atividade
/// recente — clicar numa linha abre o detalhamento do cliente (mesma tela
/// de `ClientsListPage`), que já tem a thread completa daquele hotel.
class SupportInboxPage extends StatefulWidget {
  final AuthRepository authRepository;

  const SupportInboxPage({super.key, required this.authRepository});

  @override
  State<SupportInboxPage> createState() => _SupportInboxPageState();
}

class _SupportInboxPageState extends State<SupportInboxPage> {
  final _repository = AdminSupportRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<SupportThreadSummary> _threads = const [];
  String? _openHotelId;

  @override
  void initState() {
    super.initState();
    _load();
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
      final threads = await _repository.listThreads(token: token);
      setState(() => _threads = threads);
    } on StateError catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_openHotelId != null) {
      return ClientDetailPage(
        hotelId: _openHotelId!,
        authRepository: widget.authRepository,
        onBack: () {
          setState(() => _openHotelId = null);
          _load();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Suporte', style: KonektoBrand.display(fontSize: 22)),
        const SizedBox(height: 4),
        Text('Conversas com todos os hotéis clientes.', style: KonektoBrand.body(fontSize: 13)),
        const SizedBox(height: 24),
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x1ADC2626),
              border: Border.all(color: const Color(0x4DDC2626)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_errorMessage!, style: KonektoBrand.body(fontSize: 12.5, color: const Color(0xFFF1A6A0))),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: KonektoBrand.gold))
              : _threads.isEmpty
                  ? Center(child: Text('Nenhuma conversa ainda.', style: KonektoBrand.body(fontSize: 13.5)))
                  : ListView.separated(
                      itemCount: _threads.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final thread = _threads[index];
                        return InkWell(
                          onTap: () => setState(() => _openHotelId = thread.hotelId),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: KonektoBrand.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: thread.unreadByPlatform > 0 ? KonektoBrand.gold : KonektoBrand.borderStrong,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(thread.hotelName, style: KonektoBrand.body(fontSize: 14, fontWeight: FontWeight.w700, color: KonektoBrand.cream)),
                                      const SizedBox(height: 2),
                                      Text(
                                        thread.lastMessageBody,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: KonektoBrand.body(fontSize: 12.5, color: KonektoBrand.slate),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_formatTimestamp(thread.lastMessageAt), style: KonektoBrand.body(fontSize: 11, color: KonektoBrand.slate)),
                                if (thread.unreadByPlatform > 0) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: KonektoBrand.gold, borderRadius: BorderRadius.circular(999)),
                                    child: Text(
                                      '${thread.unreadByPlatform}',
                                      style: KonektoBrand.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: KonektoBrand.ink),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

