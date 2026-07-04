import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomServiceDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic> tenantConfig;

  const RoomServiceDetailPage({
    Key? key,
    required this.product,
    required this.tenantConfig,
  }) : super(key: key);

  @override
  _RoomServiceDetailPageState createState() => _RoomServiceDetailPageState();
}

class _RoomServiceDetailPageState extends State<RoomServiceDetailPage> {
  int _quantity = 1;
  double _totalPrice = 0.0;
  final TextEditingController _observationsController = TextEditingController();

  // Função auxiliar para converter string de cor para objeto Color
  Color _hexToColor(String hexCode) {
    return Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
  }

  // Função para construir o caminho dinâmico dos assets do room service
  String _getRoomServiceAssetPath(String fileName) {
    final String tenantId = widget.tenantConfig['id'] ?? 'hotel_1';
    return 'assets/tenant_assets/hotels/$tenantId/images/room_service/$fileName';
  }

  @override
  void initState() {
    super.initState();
    _updateTotalPrice();
  }

  void _updateTotalPrice() {
    setState(() {
      _totalPrice = (widget.product['price'] ?? 0.0) * _quantity;
    });
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
      _updateTotalPrice();
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _updateTotalPrice();
      });
    }
  }

  void _addToCart() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
        final Color primaryColor = _hexToColor(widget.tenantConfig['colorPalette']['primary']);
        final Color bodyTextColor = _hexToColor(widget.tenantConfig['typography']['bodyText']['color']);
        
        final String preparationTime = widget.product['preparationTime'] ?? 'aproximadamente 30 minutos';

        return AlertDialog(
          title: Text(
            'Confirmar Pedido',
            style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Item: ${widget.product['name']}',
                  style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Quantidade: $_quantity',
                  style: GoogleFonts.getFont(fontFamily, color: bodyTextColor),
                ),
                Text(
                  'Observações: ${_observationsController.text.isEmpty ? 'Nenhuma' : _observationsController.text}',
                  style: GoogleFonts.getFont(fontFamily, color: bodyTextColor),
                ),
                const SizedBox(height: 10),
                Text(
                  'Valor Total: R\$ ${_totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Confirmar Pedido',
                style: GoogleFonts.getFont(fontFamily, color: primaryColor),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pedido enviado! Será entregue em $preparationTime.',
                      style: GoogleFonts.getFont(fontFamily, color: Colors.white),
                    ),
                    backgroundColor: primaryColor,
                    duration: const Duration(seconds: 3),
                  ),
                ).closed.then((SnackBarClosedReason reason) {
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = _hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = _hexToColor(widget.tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = _hexToColor(widget.tenantConfig['typography']['bodyText']['color']);
    final Color cardBackgroundColor = _hexToColor(widget.tenantConfig['colorPalette']['cardBackground']);
    final String imageFileName = widget.product['imageUrl']?.split('/').last ?? 'placeholder.png';
    final String imageUrl = _getRoomServiceAssetPath(imageFileName);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Image.asset(
                      imageUrl, // Usando o caminho dinâmico corrigido
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: Icon(Icons.fastfood, size: 80, color: Colors.grey[500]),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: primaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['name'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${widget.product['price']?.toStringAsFixed(2) ?? '0.00'} por unidade',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: bodyTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    widget.product['description'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: bodyTextColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Observações do pedido:',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(color: primaryColor.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: TextField(
                      controller: _observationsController,
                      maxLines: 4,
                      style: GoogleFonts.getFont(fontFamily, color: bodyTextColor),
                      decoration: InputDecoration(
                        hintText: 'Ex: Sem cebola, com mais molho, etc.',
                        hintStyle: GoogleFonts.getFont(fontFamily, color: Colors.grey.shade500),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: cardBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _decrementQuantity,
                              icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                            ),
                            Text(
                              '$_quantity',
                              style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: _incrementQuantity,
                              icon: Icon(Icons.keyboard_arrow_up, color: primaryColor),
                            ),
                          ],
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: _addToCart,
                        icon: const Icon(Icons.shopping_cart, size: 24),
                        label: Text('Adicionar', style: GoogleFonts.getFont(fontFamily, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Total: R\$ ${_totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.getFont(
                          fontFamily,
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}