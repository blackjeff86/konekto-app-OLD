import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// "Mapa do local" — info estática de quarto/wifi/endereço. Não é um mapa
/// interativo de verdade (não existe geolocalização/planta do hotel aqui);
/// é só uma tela de consulta rápida com os mesmos dados já disponíveis no
/// card expansível da Home.
class HotelInfoPage extends StatelessWidget {
  final String roomNumber;
  final String wifiNetworkName;
  final String wifiPassword;
  final GuestAppTheme theme;

  const HotelInfoPage({
    super.key,
    required this.roomNumber,
    required this.wifiNetworkName,
    required this.wifiPassword,
    required this.theme,
  });

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
                  Expanded(child: Text(l10n.hotelInfoTitle, style: theme.headline(fontSize: 22))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(theme.tokens.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(theme.hotelName, style: theme.headline(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      theme.hotelAddress?.isNotEmpty == true ? theme.hotelAddress! : l10n.addressNotProvided,
                      style: theme.body(color: theme.mutedColor),
                    ),
                    const SizedBox(height: 24),
                    _InfoRow(icon: Icons.meeting_room_outlined, label: l10n.profileRoom, value: roomNumber, theme: theme),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.wifi, label: l10n.wifiNetworkInfoLabel, value: wifiNetworkName, theme: theme),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.lock_outline, label: l10n.wifiPasswordInfoLabel, value: wifiPassword, theme: theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final GuestAppTheme theme;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.tokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
            child: Icon(icon, color: theme.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.body(fontSize: 13, color: theme.mutedColor)),
              Text(value, style: theme.headline(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
