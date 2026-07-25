import 'package:flutter/material.dart';
import 'package:konekto/templates/pulse/theme.dart';
import 'package:konekto/templates/shared/guest_template_menu_item.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Adaptado de `pulse_room_service/code.html`: cartões de vidro escuro com
/// borda dourada sutil, categorias "Molecular Cuisine/Late Night/Spirits".
/// Itens são dado de demonstração — ver `GuestTemplateMenuItem`.
class PulseRoomServiceScreen extends StatefulWidget {
  const PulseRoomServiceScreen({super.key});

  @override
  State<PulseRoomServiceScreen> createState() => _PulseRoomServiceScreenState();
}

const _categories = ['Molecular Cuisine', 'Late Night', 'Spirits'];

const _items = [
  GuestTemplateMenuItem(name: 'Crystal Ravioli', description: 'Transparent starch pasta, porcini reduction, white truffle air.', price: '\$42'),
  GuestTemplateMenuItem(name: 'Smoked Spheres', description: 'Nitrogen-flash spherified caviar of smoked tomato consommé.', price: '\$38'),
  GuestTemplateMenuItem(name: 'Thermal Negroni', description: 'Barrel-aged gin, self-heating vermouth reduction, orange oil mist.', price: '\$32'),
];

class _PulseRoomServiceScreenState extends State<PulseRoomServiceScreen> {
  int _selectedCategory = 0;
  int _cartCount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = pulseTheme;
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
                    'Molecular Cuisine'.toUpperCase(),
                    style: theme.labelCaps(color: colors.primary).copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 6),
                  Text('Chef\'s Choice — Select Tasting', style: theme.display(fontSize: 22, fontWeight: FontWeight.w600, color: colors.onSurface)),
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
                              color: selected ? colors.primary : colors.surfaceContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(theme.radiusLg),
                              border: Border.all(color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Text(_categories[index], style: theme.labelCaps(color: selected ? colors.onPrimary : colors.onSurfaceVariant)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final item in _items) ...[
                    _PulseMenuItemCard(theme: theme, item: item, onAdd: () => setState(() => _cartCount++)),
                    const SizedBox(height: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(theme.radiusXl),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.5)),
                  boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.15), blurRadius: 20)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_cartCount ${_cartCount == 1 ? 'Item' : 'Items'}', style: theme.body(fontWeight: FontWeight.w600, color: colors.onSurface)),
                    Text('View Order', style: theme.body(fontWeight: FontWeight.w700, color: colors.primary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PulseMenuItemCard extends StatelessWidget {
  final GuestTemplateTheme theme;
  final GuestTemplateMenuItem item;
  final VoidCallback onAdd;

  const _PulseMenuItemCard({required this.theme, required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.name, style: theme.display(fontSize: 16, fontWeight: FontWeight.w600, color: colors.onSurface))),
                    Text(item.price, style: theme.body(fontWeight: FontWeight.w600, color: colors.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.body(fontSize: 12.5, color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainerHighest),
              child: Icon(Icons.add, color: colors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
