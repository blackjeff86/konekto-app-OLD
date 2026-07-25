import 'package:flutter/material.dart';
import 'package:konekto/templates/horizon/theme.dart';
import 'package:konekto/templates/shared/guest_template_service_category.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `horizon_experiences_directory/code.html` — equivalente ao
/// Diretório de Serviços dos outros templates, com nome próprio
/// ("Curated Collections"). Categorias são dado de demonstração.
class HorizonExperiencesDirectoryScreen extends StatelessWidget {
  const HorizonExperiencesDirectoryScreen({super.key});

  static const _categories = [
    GuestTemplateServiceCategory(name: 'Gastronomy', icon: Icons.restaurant_outlined, featured: true),
    GuestTemplateServiceCategory(name: 'Wellness', icon: Icons.spa_outlined),
    GuestTemplateServiceCategory(name: 'Adventure', icon: Icons.sailing_outlined),
    GuestTemplateServiceCategory(name: 'Culture', icon: Icons.temple_buddhist_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = horizonTheme;
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
              Text('Curated Collections', style: theme.display(fontSize: 26, fontWeight: FontWeight.w600, color: colors.onSurface)),
              const SizedBox(height: 8),
              Text('Signature experiences, designed for your stay.', style: theme.body(color: colors.onSurfaceVariant)),
              const SizedBox(height: 20),
              _CategoryTile(theme: theme, category: featured, height: 160),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [for (final category in rest) _CategoryTile(theme: theme, category: category, height: null)],
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
          Icon(category.icon, color: category.featured ? colors.onPrimary : colors.primary, size: category.featured ? 30 : 22),
          const SizedBox(height: 8),
          Text(category.name, style: theme.display(fontSize: category.featured ? 18 : 13, fontWeight: FontWeight.w600, color: category.featured ? colors.onPrimary : colors.onSurface)),
        ],
      ),
    );
  }
}
