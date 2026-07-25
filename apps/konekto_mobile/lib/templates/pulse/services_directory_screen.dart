import 'package:flutter/material.dart';
import 'package:konekto/templates/pulse/theme.dart';
import 'package:konekto/templates/shared/guest_template_service_category.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `pulse_services_directory/code.html`: grade de cartões de
/// vidro escuro com borda dourada sutil.
class PulseServicesDirectoryScreen extends StatelessWidget {
  const PulseServicesDirectoryScreen({super.key});

  static const _categories = [
    GuestTemplateServiceCategory(name: 'Infinity Pool', icon: Icons.pool_outlined),
    GuestTemplateServiceCategory(name: 'Cyber Spa', icon: Icons.spa_outlined),
    GuestTemplateServiceCategory(name: 'Rooftop Lounge', icon: Icons.local_bar_outlined),
    GuestTemplateServiceCategory(name: 'Smart Gym', icon: Icons.fitness_center_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = pulseTheme;
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRIORITY SERVICES',
                style: theme.labelCaps(color: colors.onSurfaceVariant.withValues(alpha: 0.6)).copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text('Services', style: theme.display(fontSize: 26, fontWeight: FontWeight.w700, color: colors.onSurface)),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [for (final category in _categories) _PulseCategoryTile(theme: theme, category: category)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseCategoryTile extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateServiceCategory category;

  const _PulseCategoryTile({required this.theme, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(category.icon, color: colors.primary, size: 26),
          const SizedBox(height: 10),
          Text(category.name, style: theme.body(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
        ],
      ),
    );
  }
}
