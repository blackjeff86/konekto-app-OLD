import 'package:flutter/material.dart';
import 'package:konekto/templates/bosque/theme.dart';
import 'package:konekto/templates/shared/guest_template_menu_item.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `bosque_room_service/code.html`: cartões horizontais com
/// selo "eco/sazonal", barra de pedido flutuante fixa (não só quando há
/// item, como na Aura — o mockup do Bosque já nasce com 1 item na barra;
/// aqui ela só aparece depois do primeiro toque, mais consistente com o
/// resto do app). Itens são dado de demonstração — ver `GuestTemplateMenuItem`.
class BosqueRoomServiceScreen extends StatefulWidget {
  const BosqueRoomServiceScreen({super.key});

  @override
  State<BosqueRoomServiceScreen> createState() => _BosqueRoomServiceScreenState();
}

const _categories = ['Breakfast', 'Farm-to-Table', 'Hearth-Cooked', 'Artisanal Drinks'];

const _items = [
  (item: GuestTemplateMenuItem(name: 'Wild Mushroom Risotto', description: 'Slow-simmered arborio rice, forest-foraged chanterelles, aged parmesan, truffle oil.', price: '\$24', tag: 'Earth-friendly'), icon: Icons.eco_outlined),
  (item: GuestTemplateMenuItem(name: 'Local Cheese Board', description: 'Three regional cheeses, wildflower honey, grilled house-made sourdough.', price: '\$18', tag: 'Seasonal'), icon: Icons.local_cafe_outlined),
  (item: GuestTemplateMenuItem(name: 'Honey-Glazed Salmon', description: 'Wild-caught salmon glazed with local forest honey, roasted root vegetables.', price: '\$32', tag: 'High Protein'), icon: Icons.set_meal_outlined),
];

class _BosqueRoomServiceScreenState extends State<BosqueRoomServiceScreen> {
  int _selectedCategory = 0;
  int _cartCount = 0;
  int _cartTotal = 0;

  @override
  Widget build(BuildContext context) {
    final theme = bosqueTheme;
    final colors = theme.colors;
    return ColoredBox(
      color: colors.surface,
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room Service', style: theme.display(fontSize: 26, fontWeight: FontWeight.w600, color: colors.primary)),
                  const SizedBox(height: 6),
                  Text('Nurturing flavors delivered to your forest sanctuary.', style: theme.body(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final selected = index == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? colors.primary : colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(theme.radiusXl * 2),
                            ),
                            child: Text(_categories[index], style: theme.body(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? colors.onPrimary : colors.onSurfaceVariant)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final entry in _items) ...[
                    _BosqueMenuItemCard(
                      theme: theme,
                      item: entry.item,
                      tagIcon: entry.icon,
                      onAdd: () => setState(() {
                        _cartCount++;
                        _cartTotal += int.parse(entry.item.price.replaceAll('\$', ''));
                      }),
                    ),
                    const SizedBox(height: 20),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(theme.radiusXl),
                  boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: colors.primaryContainer, child: Text('$_cartCount', style: theme.body(fontSize: 13, fontWeight: FontWeight.w700, color: colors.onPrimaryContainer))),
                        const SizedBox(width: 10),
                        Text('${_cartCount == 1 ? 'Item' : 'Items'} — \$$_cartTotal', style: theme.body(fontWeight: FontWeight.w600, color: colors.onPrimary)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Order', style: theme.body(fontWeight: FontWeight.w700, color: colors.primary)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 18, color: colors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BosqueMenuItemCard extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateMenuItem item;
  final IconData tagIcon;
  final VoidCallback onAdd;

  const _BosqueMenuItemCard({required this.theme, required this.item, required this.tagIcon, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(theme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 96,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11)),
            ),
            child: Icon(Icons.restaurant_outlined, color: colors.outline),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.name, style: theme.display(fontSize: 16, fontWeight: FontWeight.w600, color: colors.primary))),
                      Text(item.price, style: theme.body(fontWeight: FontWeight.w600, color: colors.secondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.body(fontSize: 12.5, color: colors.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.tag != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tagIcon, size: 14, color: colors.tertiary),
                            const SizedBox(width: 4),
                            Text(item.tag!, style: theme.body(fontSize: 11, color: colors.tertiary)),
                          ],
                        ),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primaryContainer),
                          child: Icon(Icons.add, color: colors.onPrimaryContainer, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
