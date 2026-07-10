import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/app/tenants/services_page.dart' show hexToColor;
import 'package:konekto/data/guest_claim_repository.dart';
import 'package:konekto/data/notices_repository.dart';
import 'package:konekto/models/stay_notice.dart';

/// Avisos da recepção pro quarto do hóspede (ex: "seu jantar está
/// pronto", "checkout às 12h") — só leitura, sem resposta.
class NoticesPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;

  const NoticesPage({super.key, required this.tenantConfig});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  final GuestClaimRepository _guestClaimRepository = GuestClaimRepository();
  final NoticesRepository _noticesRepository = NoticesRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<StayNotice> _notices = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = await _guestClaimRepository.getStoredToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Não foi possível identificar sua sessão.';
        _isLoading = false;
      });
      return;
    }
    try {
      final notices = await _noticesRepository.getNotices(token: token);
      if (!mounted) return;
      setState(() {
        _notices = notices;
        _errorMessage = null;
      });
    } on StateError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month às $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(widget.tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(widget.tenantConfig['typography']['bodyText']['color']);
    final Color cardBackgroundColor = hexToColor(widget.tenantConfig['colorPalette']['cardBackground']);
    final Color cardBorderColor = hexToColor(widget.tenantConfig['colorPalette']['dividerColor']);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Avisos',
                      style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null && _notices.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 14),
                                ),
                              ),
                            ],
                          )
                        : _notices.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'Nenhum aviso da recepção até agora.',
                                      style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 14),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                itemCount: _notices.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final notice = _notices[index];
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: cardBackgroundColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: cardBorderColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notice.message,
                                          style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDateTime(notice.createdAt),
                                          style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
