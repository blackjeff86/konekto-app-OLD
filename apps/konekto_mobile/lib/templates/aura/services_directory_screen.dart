import 'package:flutter/material.dart';
import 'package:konekto/templates/aura/theme.dart';
import 'package:konekto/templates/shared/guest_template_service_category.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `aura_services_directory/code.html`: cartão grande em
/// destaque (Spa & Wellness) + grade 2 colunas pro resto, e um cartão de
/// "Bespoke Requests" levando pro concierge. Fotos de fundo do mockup
/// viram um tom sólido da paleta com ícone — sem foto de estoque genérica.
class AuraServicesDirectoryScreen extends StatelessWidget {
  const AuraServicesDirectoryScreen({super.key});

  static const _categories = [
    GuestTemplateServiceCategory(name: 'Spa & Wellness', icon: Icons.spa_outlined, featured: true),
    GuestTemplateServiceCategory(name: 'Fitness Center', icon: Icons.fitness_center_outlined),
    GuestTemplateServiceCategory(name: 'Housekeeping', icon: Icons.cleaning_services_outlined),
    GuestTemplateServiceCategory(name: 'Laundry', icon: Icons.local_laundry_service_outlined),
    GuestTemplateServiceCategory(name: 'Transportation', icon: Icons.directions_car_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = auraTheme;
    final colors = theme.colors;
    final featured = _categories.first;
    final rest = _categories.skip(1).toList();
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Services', style: theme.display(fontSize: 30, fontWeight: FontWeight.w400, color: colors.onSurface)),
              const SizedBox(height: 8),
              Text('Refined essentials tailored to your journey.', style: theme.body(color: colors.onSurfaceVariant)),
              const SizedBox(height: 20),
              _CategoryTile(theme: theme, category: featured, height: 180),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [for (final category in rest) _CategoryTile(theme: theme, category: category, height: null)],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: colors.secondaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(theme.radiusLg)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(theme.radiusDefault)),
                      child: Icon(Icons.support_agent, color: colors.onPrimary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bespoke Requests', style: theme.body(fontWeight: FontWeight.w600, color: colors.primary)),
                          const SizedBox(height: 4),
                          Text(
                            'Seeking something more specific? Our concierge team is available 24/7.',
                            style: theme.body(fontSize: 12.5, color: colors.onSecondaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateServiceCategory category;
  final double? height;

  const _CategoryTile({required this.theme, required this.category, this.height});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: category.featured ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(theme.radiusXl),
      ),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(category.icon, color: category.featured ? colors.onPrimary : colors.primary, size: category.featured ? 32 : 24),
          const SizedBox(height: 8),
          Text(category.name, style: theme.display(fontSize: category.featured ? 20 : 15, fontWeight: FontWeight.w600, color: category.featured ? colors.onPrimary : colors.onSurface)),
        ],
      ),
    );
  }
}
