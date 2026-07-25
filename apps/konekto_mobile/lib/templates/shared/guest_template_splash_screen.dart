import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Splash de identidade — logo/wordmark + tagline + barra de carregamento,
/// reaproveitado pelos 4 templates (só texto/paleta muda). Os 4 mockups do
/// Stitch usam foto de fundo full-bleed (`aura_splash_screen`,
/// `bosque_splash_screen` etc.), mas essas fotos são estoque genérico do
/// gerador, não do hotel real — usar um fundo sólido/gradiente da própria
/// paleta em vez de fingir ter uma foto do hotel.
///
/// Ainda não ligado a nenhum fluxo real (o app hoje vai direto do código de
/// acesso pra `TenantHomePage`, sem splash) — Fase 4 decide se/como isso
/// entra no fluxo de fato.
class GuestTemplateSplashScreen extends StatelessWidget {
  final GuestTemplateTheme theme;
  final String wordmark;
  final String tagline;
  final String footnote;

  const GuestTemplateSplashScreen({
    super.key,
    required this.theme,
    required this.wordmark,
    required this.tagline,
    required this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _atmosphericBlob(colors.primaryContainer.withValues(alpha: 0.35), 220),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _atmosphericBlob(colors.secondaryContainer.withValues(alpha: 0.3), 180),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wordmark,
                  style: theme.display(fontSize: 40, fontWeight: FontWeight.w400, color: colors.primary).copyWith(letterSpacing: 6),
                ),
                const SizedBox(height: 10),
                Text(
                  tagline.toUpperCase(),
                  style: theme.labelCaps(color: colors.outline).copyWith(letterSpacing: 3),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 120,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: colors.outlineVariant.withValues(alpha: 0.4),
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              footnote,
              textAlign: TextAlign.center,
              style: theme.body(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _atmosphericBlob(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
