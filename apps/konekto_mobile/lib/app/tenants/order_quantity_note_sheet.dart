import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/models/coupon.dart';

/// Resultado escolhido pelo hóspede no [showOrderQuantityNoteSheet] —
/// `null` quando ele fecha o modal sem confirmar.
class OrderQuantityNoteResult {
  final int quantity;
  final String? note;
  final String? couponId;

  const OrderQuantityNoteResult({required this.quantity, this.note, this.couponId});
}

/// Modal pra escolher quantidade e adicionar uma observação antes de
/// confirmar um pedido novo, ou pra editar esses dois campos num pedido já
/// feito (enquanto ainda `pending`). Usado tanto em
/// `service_item_detail_page.dart` (pedido novo) quanto em
/// `my_orders_page.dart` (edição).
///
/// `availableCoupons` só aparece quando o item tem preço (`itemPrice !=
/// null`) — o hóspede escolhe da lista (estilo iFood), nunca digita um
/// código.
Future<OrderQuantityNoteResult?> showOrderQuantityNoteSheet(
  BuildContext context, {
  required String itemName,
  required String fontFamily,
  required Color primaryColor,
  required Color backgroundColor,
  required Color bodyTextColor,
  int initialQuantity = 1,
  String? initialNote,
  String confirmLabel = 'Confirmar',
  double? itemPrice,
  List<Coupon> availableCoupons = const [],
}) {
  return showModalBottomSheet<OrderQuantityNoteResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OrderQuantityNoteSheet(
      itemName: itemName,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      bodyTextColor: bodyTextColor,
      initialQuantity: initialQuantity,
      initialNote: initialNote,
      confirmLabel: confirmLabel,
      itemPrice: itemPrice,
      availableCoupons: availableCoupons,
    ),
  );
}

class _OrderQuantityNoteSheet extends StatefulWidget {
  final String itemName;
  final String fontFamily;
  final Color primaryColor;
  final Color backgroundColor;
  final Color bodyTextColor;
  final int initialQuantity;
  final String? initialNote;
  final String confirmLabel;
  final double? itemPrice;
  final List<Coupon> availableCoupons;

  const _OrderQuantityNoteSheet({
    required this.itemName,
    required this.fontFamily,
    required this.primaryColor,
    required this.backgroundColor,
    required this.bodyTextColor,
    required this.initialQuantity,
    required this.initialNote,
    required this.confirmLabel,
    required this.itemPrice,
    required this.availableCoupons,
  });

  @override
  State<_OrderQuantityNoteSheet> createState() => _OrderQuantityNoteSheetState();
}

class _OrderQuantityNoteSheetState extends State<_OrderQuantityNoteSheet> {
  late int _quantity;
  late final TextEditingController _noteController;
  String? _selectedCouponId;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _subtotal => (widget.itemPrice ?? 0) * _quantity;

  void _confirm() {
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      OrderQuantityNoteResult(quantity: _quantity, note: note.isEmpty ? null : note, couponId: _selectedCouponId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: widget.bodyTextColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.itemName,
                style: GoogleFonts.getFont(widget.fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: widget.primaryColor),
              ),
              const SizedBox(height: 20),
              Text(
                'Quantidade',
                style: GoogleFonts.getFont(widget.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: widget.bodyTextColor),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    color: widget.primaryColor,
                    onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(widget.fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: widget.primaryColor),
                    ),
                  ),
                  _QtyButton(icon: Icons.add, color: widget.primaryColor, onTap: () => setState(() => _quantity++)),
                ],
              ),
              if (widget.availableCoupons.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Cupom',
                  style: GoogleFonts.getFont(widget.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: widget.bodyTextColor),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CouponChoiceCard(
                        title: 'Sem cupom',
                        subtitle: '',
                        selected: _selectedCouponId == null,
                        enabled: true,
                        fontFamily: widget.fontFamily,
                        primaryColor: widget.primaryColor,
                        bodyTextColor: widget.bodyTextColor,
                        onTap: () => setState(() => _selectedCouponId = null),
                      ),
                      for (final coupon in widget.availableCoupons)
                        _CouponChoiceCard(
                          title: coupon.discountLabel,
                          subtitle: coupon.title,
                          selected: _selectedCouponId == coupon.id,
                          enabled: coupon.eligible && coupon.meetsMinOrder(_subtotal),
                          disabledReason: !coupon.eligible
                              ? 'já usado'
                              : (!coupon.meetsMinOrder(_subtotal) ? 'mín. R\$ ${coupon.minOrderValue!.toStringAsFixed(2)}' : null),
                          fontFamily: widget.fontFamily,
                          primaryColor: widget.primaryColor,
                          bodyTextColor: widget.bodyTextColor,
                          onTap: () => setState(() => _selectedCouponId = coupon.id),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Observação (opcional)',
                style: GoogleFonts.getFont(widget.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: widget.bodyTextColor),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 250,
                style: GoogleFonts.getFont(widget.fontFamily, fontSize: 14, color: widget.bodyTextColor),
                decoration: InputDecoration(
                  hintText: 'Ex: sem cebola, trocar por suco de laranja...',
                  hintStyle: GoogleFonts.getFont(widget.fontFamily, fontSize: 13, color: widget.bodyTextColor.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(widget.confirmLabel, style: GoogleFonts.getFont(widget.fontFamily, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: color,
      disabledColor: color.withValues(alpha: 0.3),
      style: IconButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1), shape: const CircleBorder()),
    );
  }
}

/// Um cartão selecionável de cupom (ou "Sem cupom") na lista horizontal —
/// estilo iFood: o hóspede escolhe da lista, nunca digita código. Cupons
/// não elegíveis (já usados, ou pedido não bate o mínimo) ficam visíveis
/// mas desabilitados, com o motivo.
class _CouponChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final String? disabledReason;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final VoidCallback onTap;

  const _CouponChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    this.disabledReason,
    required this.fontFamily,
    required this.primaryColor,
    required this.bodyTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withValues(alpha: 0.12) : Colors.transparent,
            border: Border.all(color: selected ? primaryColor : bodyTextColor.withValues(alpha: 0.25), width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined, size: 18, color: primaryColor),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.getFont(fontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.getFont(fontFamily, fontSize: 11, color: bodyTextColor),
                ),
              if (disabledReason != null)
                Text(
                  disabledReason!,
                  style: GoogleFonts.getFont(fontFamily, fontSize: 10, color: Colors.red.shade700),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
