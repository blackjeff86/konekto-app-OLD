import 'package:flutter/material.dart';
import 'package:konekto/templates/horizon/theme.dart';
import 'package:konekto/templates/shared/guest_template_menu_item.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `horizon_room_service/code.html`. Itens são dado de
/// demonstração — ver `GuestTemplateMenuItem`.
class HorizonRoomServiceScreen extends StatefulWidget {
  const HorizonRoomServiceScreen({super.key});

  @override
  State<HorizonRoomServiceScreen> createState() => _HorizonRoomServiceScreenState();
}

const _categories = ['Signature Breakfast', 'Lunch by the Pool', 'Sunset Cocktails', 'Amenities'];

const _items = [
  GuestTemplateMenuItem(name: 'Avocado Tartine', description: 'Sourdough, heirloom tomato, poached egg, chili flakes.', price: '\$24'),
  GuestTemplateMenuItem(name: 'Honeycomb Pancakes', description: 'Fresh berries, maple syrup, cream.', price: '\$22'),
  GuestTemplateMenuItem(name: 'Horizon Acai Bowl', description: 'Organic acai, seasonal tropical fruits.', price: '\$18'),
  GuestTemplateMenuItem(name: 'Estate Charcuterie', description: 'Local cheeses, cured meats, figs.', price: '\$38'),
];

class _HorizonRoomServiceScreenState extends State<HorizonRoomServiceScreen> {
  int _selectedCategory = 0;
  int _cartCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = horizonTheme;
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
                  Text('Curated Experience', style: theme.body(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary).copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text('Most Requested', style: theme.display(fontSize: 24, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final selected = index == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? colors.primary : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(theme.radiusXl * 2),
                            ),
                            child: Text(_categories[index], style: theme.body(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? colors.onPrimary : colors.onSurfaceVariant)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final item in _items) ...[
                    _HorizonMenuItemCard(theme: theme, item: item, onAdd: () => setState(() => _cartCount++)),
                    const SizedBox(height: 16),
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
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(theme.radiusXl),
                  boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_cartCount ${_cartCount == 1 ? 'Item' : 'Items'}', style: theme.body(fontWeight: FontWeight.w600, color: colors.onPrimary)),
                    Text('View your order', style: theme.body(fontWeight: FontWeight.w700, color: colors.onPrimary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HorizonMenuItemCard extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateMenuItem item;
  final VoidCallback onAdd;

  const _HorizonMenuItemCard({required this.theme, required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surfaceContainerLowest, borderRadius: BorderRadius.circular(theme.radiusXl), border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(theme.radiusLg)),
            child: Icon(Icons.restaurant_outlined, color: colors.outline),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.name, style: theme.display(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface))),
                    Text(item.price, style: theme.body(fontWeight: FontWeight.w600, color: colors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.body(fontSize: 12.5, color: colors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primaryContainer),
                      child: Icon(Icons.add, color: colors.onPrimaryContainer, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
