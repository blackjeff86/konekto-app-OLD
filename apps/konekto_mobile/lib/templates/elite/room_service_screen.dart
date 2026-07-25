import 'package:flutter/material.dart';
import 'package:konekto/templates/elite/theme.dart';
import 'package:konekto/templates/shared/guest_template_menu_item.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `lite_room_service/code.html`: lista editorial (sem imagem
/// de destaque por item, tipografia carregando o peso visual), categorias
/// em texto sublinhado em vez de chip preenchido. Itens são dado de
/// demonstração — ver `GuestTemplateMenuItem`.
class EliteRoomServiceScreen extends StatefulWidget {
  const EliteRoomServiceScreen({super.key});

  @override
  State<EliteRoomServiceScreen> createState() => _EliteRoomServiceScreenState();
}

const _categories = ['Signature Breakfast', "Chef's Tasting", 'Wine Cellar'];

const _items = [
  GuestTemplateMenuItem(name: 'Lobster Benedict', description: 'Poached lobster, hollandaise, brioche, Ossetra caviar.', price: '\$58'),
  GuestTemplateMenuItem(name: 'Wagyu Carpaccio', description: 'A5 Wagyu, black truffle, aged parmesan, arugula.', price: '\$72'),
  GuestTemplateMenuItem(name: 'Truffle Scrambled Eggs', description: 'Farm eggs, black truffle shavings, chives.', price: '\$45'),
  GuestTemplateMenuItem(name: 'Smoked Salmon', description: 'House-cured salmon, dill crème fraîche, capers.', price: '\$38'),
];

class _EliteRoomServiceScreenState extends State<EliteRoomServiceScreen> {
  int _selectedCategory = 0;
  int _cartCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = eliteTheme;
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Culinary Excellence, Delivered to Your Door.',
                    style: theme.display(fontSize: 22, fontWeight: FontWeight.w400, color: colors.primary),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: List.generate(_categories.length, (index) {
                      final selected = index == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = index),
                        child: Text(
                          _categories[index].toUpperCase(),
                          style: theme
                              .body(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? colors.primary : colors.onSurfaceVariant.withValues(alpha: 0.6))
                              .copyWith(letterSpacing: 1.2, decoration: selected ? TextDecoration.underline : null, decorationColor: colors.secondary),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  for (final item in _items) ...[
                    _EliteMenuItemRow(theme: theme, item: item, onAdd: () => setState(() => _cartCount++)),
                    Divider(color: colors.outlineVariant.withValues(alpha: 0.4), height: 32),
                  ],
                ],
              ),
            ),
          ),
          if (_cartCount > 0)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: colors.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_cartCount ${_cartCount == 1 ? 'ITEM' : 'ITEMS'}', style: theme.body(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onPrimary).copyWith(letterSpacing: 1.5)),
                    Text('VIEW ORDER', style: theme.body(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onPrimary).copyWith(letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EliteMenuItemRow extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateMenuItem item;
  final VoidCallback onAdd;

  const _EliteMenuItemRow({required this.theme, required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: theme.display(fontSize: 18, fontWeight: FontWeight.w400, color: colors.onSurface)),
              const SizedBox(height: 6),
              Text(item.description, style: theme.body(fontSize: 13, color: colors.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(item.price, style: theme.body(fontSize: 14, fontWeight: FontWeight.w600, color: colors.secondary)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.outline)),
            child: Icon(Icons.add, color: colors.primary, size: 18),
          ),
        ),
      ],
    );
  }
}
