import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/theme/guest_app_theme.dart';

class ExpandableCard extends StatefulWidget {
  final String roomNumber;
  final String wifiNetworkName;
  final String wifiPassword;
  final GuestAppTheme theme;
  final String? title;
  final IconData icon;

  /// Verde Pousada usa uma versão "achatada" (sem borda/sombra, fundo
  /// levemente tintado) — mais próxima de uma linha de acordeão editorial
  /// do que um cartão elevado (o estilo padrão, usado pela Amara Bay).
  final bool flat;

  const ExpandableCard({
    super.key,
    required this.roomNumber,
    required this.wifiNetworkName,
    required this.wifiPassword,
    required this.theme,
    this.title,
    this.icon = Icons.door_front_door_outlined,
    this.flat = false,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  GuestAppTheme get theme => widget.theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.title ?? l10n.roomWifiDetails;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.flat ? 4 : 16),
      decoration: BoxDecoration(
        color: widget.flat ? theme.accentSoft : theme.cardBg,
        borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
        border: widget.flat ? null : Border.all(color: theme.borderColor),
        boxShadow: widget.flat ? null : theme.tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: widget.flat ? 12 : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!widget.flat) ...[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
                          child: Icon(widget.icon, color: theme.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                      ] else ...[
                        Icon(widget.icon, color: theme.accent, size: 18),
                        const SizedBox(width: 10),
                      ],
                      Text(title, style: theme.headline(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down, color: theme.accent),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            Divider(color: theme.borderColor),
            const SizedBox(height: 16),
            _buildDetailRow(icon: Icons.person_pin, text: l10n.roomNumberLabel(widget.roomNumber)),
            const SizedBox(height: 12),
            _buildDetailRow(icon: Icons.wifi, text: l10n.wifiNetworkLabel(widget.wifiNetworkName)),
            const SizedBox(height: 12),
            _buildDetailRow(icon: Icons.lock, text: l10n.wifiPasswordLabel(widget.wifiPassword)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: theme.accent),
        const SizedBox(width: 8),
        Text(text, style: theme.body(color: theme.mutedColor)),
      ],
    );
  }
}
