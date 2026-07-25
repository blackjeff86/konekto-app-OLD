import 'package:flutter/material.dart';
import 'package:konekto/templates/aura/theme.dart';
import 'package:konekto/templates/shared/guest_template_menu_item.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `aura_room_service/code.html`: busca, categorias em chip
/// horizontal, cartões de item (imagem + descrição + preço + botão de
/// adicionar), barra flutuante de carrinho. Itens são dado de demonstração
/// — ver `GuestTemplateMenuItem`.
class AuraRoomServiceScreen extends StatefulWidget {
  const AuraRoomServiceScreen({super.key});

  @override
  State<AuraRoomServiceScreen> createState() => _AuraRoomServiceScreenState();
}

const _categories = ['All', 'Food', 'Drinks', 'Amenities', 'Laundry'];

const _items = [
  GuestTemplateMenuItem(name: 'Artisan Wagyu Burger', description: 'Caramelized onions, truffle aioli, aged cheddar, house-made brioche bun.', price: '\$28'),
  GuestTemplateMenuItem(name: 'Heirloom Grain Bowl', description: 'Quinoa, roasted roots, Hass avocado, zesty lemon-tahini dressing.', price: '\$24'),
  GuestTemplateMenuItem(name: 'Hibiscus Elixir', description: 'Sparkling botanicals infused with wild hibiscus and a hint of lavender.', price: '\$16'),
  GuestTemplateMenuItem(name: 'Patisserie Selection', description: 'Six seasonal macarons handcrafted by our executive pastry chef.', price: '\$18'),
];

class _AuraRoomServiceScreenState extends State<AuraRoomServiceScreen> {
  int _selectedCategory = 0;
  int _cartCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = auraTheme;
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
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search menu items...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(theme.radiusXl), borderSide: BorderSide.none),
                    ),
                  ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? colors.primary : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(theme.radiusXl * 2),
                            ),
                            child: Text(_categories[index], style: theme.labelCaps(color: selected ? colors.onPrimary : colors.onSurfaceVariant)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final item in _items) ...[
                    _AuraMenuItemCard(theme: theme, item: item, onAdd: () => setState(() => _cartCount++)),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          if (_cartCount > 0)
            Positioned(
              bottom: 24,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(theme.radiusXl),
                  boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_basket_outlined, color: colors.onPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text('$_cartCount ${_cartCount == 1 ? 'Item' : 'Items'}', style: theme.labelCaps(color: colors.onPrimary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuraMenuItemCard extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateMenuItem item;
  final VoidCallback onAdd;

  const _AuraMenuItemCard({required this.theme, required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(theme.radiusXl)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 84,
            height: 84,
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
                    Expanded(child: Text(item.name, style: theme.body(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurface))),
                    Text(item.price, style: theme.body(fontSize: 16, fontWeight: FontWeight.w600, color: colors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.body(fontSize: 13, color: colors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.secondaryContainer),
                      child: Icon(Icons.add, color: colors.onSecondaryContainer, size: 18),
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
