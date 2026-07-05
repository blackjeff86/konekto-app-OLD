import 'package:flutter/material.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Painel de seção ainda não implementada (Hóspedes, Pedidos,
/// Configurações) — deliberadamente não simula dados reais, já que essas
/// tabelas (guests/orders) ainda não existem no Postgres.
///
/// Em vez de um card genérico "em breve" flutuando no centro, o corpo imita
/// uma página de registro de hóspedes com linhas fantasma — o motivo visual
/// do portal inteiro (um "balcão de concierge" digital, não um admin
/// genérico): cada linha vazia é um convite, não um vazio sem propósito.
class PlaceholderSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const PlaceholderSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: KonektoBrand.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KonektoBrand.borderStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: KonektoBrand.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 19, color: KonektoBrand.goldLight),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: KonektoBrand.display(fontSize: 17)),
                          const SizedBox(height: 4),
                          Text(description, style: KonektoBrand.body(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: KonektoBrand.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: KonektoBrand.gold.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'Em breve',
                        style: KonektoBrand.body(fontSize: 11, fontWeight: FontWeight.w600, color: KonektoBrand.goldLight),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: KonektoBrand.borderStrong),
              for (var i = 0; i < 5; i++) ...[
                _GhostRow(muted: i > 0),
                if (i < 4) const Divider(height: 1, color: KonektoBrand.borderStrong, indent: 24, endIndent: 24),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma linha vazia de "registro" — como uma página de livro-razão esperando
/// ser preenchida, não uma barra de esqueleto genérica.
class _GhostRow extends StatelessWidget {
  final bool muted;

  const _GhostRow({required this.muted});

  @override
  Widget build(BuildContext context) {
    final opacity = muted ? 0.55 : 0.85;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: KonektoBrand.borderStrong),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08 * opacity * 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 76,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05 * opacity * 2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: KonektoBrand.borderStrong),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
