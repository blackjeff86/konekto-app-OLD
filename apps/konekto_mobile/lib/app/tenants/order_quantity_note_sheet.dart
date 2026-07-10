import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Resultado escolhido pelo hóspede no [showOrderQuantityNoteSheet] —
/// `null` quando ele fecha o modal sem confirmar.
class OrderQuantityNoteResult {
  final int quantity;
  final String? note;

  const OrderQuantityNoteResult({required this.quantity, this.note});
}

/// Modal pra escolher quantidade e adicionar uma observação antes de
/// confirmar um pedido novo, ou pra editar esses dois campos num pedido já
/// feito (enquanto ainda `pending`). Usado tanto em
/// `service_item_detail_page.dart` (pedido novo) quanto em
/// `my_orders_page.dart` (edição).
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

  const _OrderQuantityNoteSheet({
    required this.itemName,
    required this.fontFamily,
    required this.primaryColor,
    required this.backgroundColor,
    required this.bodyTextColor,
    required this.initialQuantity,
    required this.initialNote,
    required this.confirmLabel,
  });

  @override
  State<_OrderQuantityNoteSheet> createState() => _OrderQuantityNoteSheetState();
}

class _OrderQuantityNoteSheetState extends State<_OrderQuantityNoteSheet> {
  late int _quantity;
  late final TextEditingController _noteController;

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

  void _confirm() {
    final note = _noteController.text.trim();
    Navigator.of(context).pop(OrderQuantityNoteResult(quantity: _quantity, note: note.isEmpty ? null : note));
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
