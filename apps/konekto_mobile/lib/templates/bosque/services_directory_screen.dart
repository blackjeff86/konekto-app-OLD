import 'package:flutter/material.dart';
import 'package:konekto/templates/bosque/theme.dart';
import 'package:konekto/templates/shared/guest_template_service_category.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `bosque_services_directory/code.html` ("Curated
/// Experiences").
class BosqueServicesDirectoryScreen extends StatelessWidget {
  const BosqueServicesDirectoryScreen({super.key});

  static const _categories = [
    GuestTemplateServiceCategory(name: 'Guided Nature Hikes', icon: Icons.hiking),
    GuestTemplateServiceCategory(name: 'Horseback Riding', icon: Icons.pets_outlined),
    GuestTemplateServiceCategory(name: 'Local Vineyard Tour', icon: Icons.wine_bar_outlined),
    GuestTemplateServiceCategory(name: 'Spa Booking', icon: Icons.spa_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = bosqueTheme;
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Curated Experiences', style: theme.display(fontSize: 26, fontWeight: FontWeight.w600, color: colors.primary)),
              const SizedBox(height: 8),
              Text('Guided moments in the heart of the forest.', style: theme.body(color: colors.onSurfaceVariant)),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [for (final category in _categories) _BosqueCategoryTile(theme: theme, category: category)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BosqueCategoryTile extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateServiceCategory category;

  const _BosqueCategoryTile({required this.theme, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: Icon(category.icon, color: colors.primary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(category.name, style: theme.display(fontSize: 15, fontWeight: FontWeight.w600, color: colors.primary)),
        ],
      ),
    );
  }
}
