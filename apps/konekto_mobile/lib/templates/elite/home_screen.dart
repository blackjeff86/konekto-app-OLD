import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/guest_template_content_params.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Elite: cartão de residência preto/dourado com botões retangulares
/// "Gerenciar estadia"/"Ver mapa", grade 2x2 de acesso rápido com contorno
/// fino (sem preenchimento — a mesma linguagem "quiet luxury" do Casa
/// Marechal antigo, não por coincidência: os dois mockups vêm da mesma
/// vertical "heritage/quiet luxury"). Adaptado de `lite_home/code.html` —
/// o "Access Code" do mockup foi omitido (não é um dado real hoje; o app
/// usa código de acesso só pra login inicial, não como chave de quarto).
class EliteHomeContent extends StatelessWidget {
  final GuestTemplateContentParams params;

  const EliteHomeContent({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = params.theme;
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: colors.surfaceContainerHighest, child: Icon(Icons.person_outline, color: colors.primary)),
            const Spacer(),
            _EliteBell(theme: theme, count: params.notificationCount, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          l10n.homeWelcomeBack,
          style: theme.body(fontSize: 11, fontWeight: FontWeight.w600, color: colors.secondary).copyWith(letterSpacing: 3),
        ),
        const SizedBox(height: 8),
        Text(l10n.homeWelcomeName(params.userName), style: theme.display(fontSize: 30, fontWeight: FontWeight.w400, color: colors.onSurface)),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(theme.radiusLg),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(l10n.roomNumberLabel(params.roomNumber), style: theme.display(fontSize: 22, fontWeight: FontWeight.w400, color: colors.primary))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(theme.radiusXl)),
                    child: Text(
                      l10n.eliteTag.toUpperCase(),
                      style: theme.body(fontSize: 9, fontWeight: FontWeight.w700, color: colors.onPrimary).copyWith(letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.wifi, color: colors.secondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.wifiNetworkLabel(params.wifiNetworkName), style: theme.body(fontSize: 10, color: colors.onSurfaceVariant.withValues(alpha: 0.7))),
                        Text(l10n.wifiPasswordLabel(params.wifiPassword), style: theme.body(fontSize: 15, color: colors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => params.onOpenMyOrders(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        l10n.quickTileHistory.toUpperCase(),
                        style: theme.body(fontSize: 11, fontWeight: FontWeight.w700, color: colors.onPrimary).copyWith(letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => params.onOpenHotelInfo(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        l10n.quickTileMap.toUpperCase(),
                        style: theme.body(fontSize: 11, fontWeight: FontWeight.w700, color: colors.primary).copyWith(letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _EliteAction(theme: theme, icon: Icons.room_service_outlined, label: l10n.quickTileServices, onTap: params.onNavigateToServices),
            _EliteAction(theme: theme, icon: Icons.campaign_outlined, label: l10n.quickTileNotices, onTap: () => params.onOpenNotices(context)),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _EliteBell extends StatelessWidget {
  final GuestTemplateTheme theme;
  final int count;
  final VoidCallback onTap;

  const _EliteBell({required this.theme, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: colors.primary),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: colors.secondary, border: Border.all(color: colors.surface, width: 1.5))),
            ),
        ],
      ),
    );
  }
}

class _EliteAction extends StatelessWidget {
  final GuestTemplateTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EliteAction({required this.theme, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(theme.radiusLg),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.secondary, size: 26),
            const SizedBox(height: 10),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.body(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.primary).copyWith(letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
