import 'package:flutter/material.dart';
import 'package:konekto/templates/elite/theme.dart';
import 'package:konekto/templates/shared/guest_template_service_category.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `lite_services_directory/code.html`: lista editorial, sem
/// grade de cartões coloridos — texto carregando o peso, contorno fino nas
/// bordas.
class EliteServicesDirectoryScreen extends StatelessWidget {
  const EliteServicesDirectoryScreen({super.key});

  static const _categories = [
    GuestTemplateServiceCategory(name: 'Signature Spa', icon: Icons.spa_outlined),
    GuestTemplateServiceCategory(name: 'Fine Dining', icon: Icons.restaurant_outlined),
    GuestTemplateServiceCategory(name: 'Private Tours', icon: Icons.explore_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = eliteTheme;
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Services', style: theme.display(fontSize: 28, fontWeight: FontWeight.w400, color: colors.primary)),
              const SizedBox(height: 24),
              for (final category in _categories) ...[
                _EliteCategoryRow(theme: theme, category: category),
                Divider(color: colors.outlineVariant.withValues(alpha: 0.4), height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EliteCategoryRow extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateServiceCategory category;

  const _EliteCategoryRow({required this.theme, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.outline)),
          child: Icon(category.icon, color: colors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(category.name, style: theme.display(fontSize: 17, fontWeight: FontWeight.w400, color: colors.onSurface))),
        Icon(Icons.chevron_right, color: colors.outline),
      ],
    );
  }
}
