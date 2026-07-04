import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'room_service_detail_page.dart';

class RoomServicePage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final Map<String, dynamic> roomServiceMenu;

  const RoomServicePage({
    super.key,
    required this.tenantConfig,
    required this.roomServiceMenu,
  });

  Color hexToColor(String hexCode) {
    return Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
  }

  FontWeight _getFontWeight(String? weight) {
    switch (weight) {
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w400':
        return FontWeight.w400;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      case 'bold':
        return FontWeight.bold;
      default:
        return FontWeight.w400;
    }
  }

  String _getRoomServiceAssetPath(String fileName) {
    final String tenantId = tenantConfig['id'] ?? 'hotel_1';
    return 'assets/tenant_assets/hotels/$tenantId/images/room_service/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    final pageConfig = roomServiceMenu['pageConfig'] ?? {};
    final menuCategories = roomServiceMenu['menu'] ?? [];

    final String layoutType = pageConfig['layoutType'] ?? 'list';

    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);
    final String fontFamily = tenantConfig['typography']['fontFamily'];

    final roomServiceStyles = pageConfig['styles'] ?? {};
    final roomServiceTextStyles = pageConfig['textStyles'] ?? {};
    final roomServiceLayoutStyles = pageConfig['layoutStyles'] ?? {};

    final Color cardBackgroundColor = hexToColor(roomServiceStyles['cardBackgroundColor']);
    final Color cardBorderColor = hexToColor(roomServiceStyles['cardBorderColor']);

    String pageTitle = pageConfig['title'] ?? 'Serviço de Quarto';
    final String headerImageFileName = pageConfig['headerImage']?.split('/').last ?? "placeholder.png";
    final String headerImageUrl = _getRoomServiceAssetPath(headerImageFileName);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: (roomServiceLayoutStyles['screenPadding'] as int?)?.toDouble() ?? 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: primaryColor,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        pageTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.getFont(
                          fontFamily,
                          color: primaryColor,
                          fontSize: (roomServiceTextStyles['pageTitle']?['fontSize'] as int?)?.toDouble() ?? 24,
                          fontWeight: _getFontWeight(roomServiceTextStyles['pageTitle']?['fontWeight']),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular((roomServiceLayoutStyles['headerImage']?['borderRadius'] as int?)?.toDouble() ?? 16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular((roomServiceLayoutStyles['headerImage']?['borderRadius'] as int?)?.toDouble() ?? 16),
                    child: Image.asset(
                      headerImageUrl,
                      height: (roomServiceLayoutStyles['headerImage']?['height'] as int?)?.toDouble() ?? 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/app_assets/images/placeholder.png',
                          height: (roomServiceLayoutStyles['headerImage']?['height'] as int?)?.toDouble() ?? 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...menuCategories.expand((category) {
                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        category['category'],
                        style: GoogleFonts.getFont(
                          fontFamily,
                          color: primaryColor,
                          fontSize: (roomServiceTextStyles['categoryTitle']?['fontSize'] as int?)?.toDouble() ?? 20,
                          fontWeight: _getFontWeight(roomServiceTextStyles['categoryTitle']?['fontWeight']),
                        ),
                      ),
                    ),
                    if (layoutType == 'grid')
                      _buildItemsGrid(
                        context,
                        category['items'],
                        fontFamily,
                        primaryColor,
                        bodyTextColor,
                        cardBackgroundColor,
                        cardBorderColor,
                        roomServiceTextStyles,
                        roomServiceLayoutStyles['grid']
                      )
                    else
                      _buildItemsList(
                        context,
                        category['items'],
                        fontFamily,
                        primaryColor,
                        bodyTextColor,
                        cardBackgroundColor,
                        cardBorderColor,
                        roomServiceTextStyles,
                        roomServiceLayoutStyles['list']
                      ),
                  ];
                }).toList(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(
      BuildContext context,
      List<dynamic> items,
      String fontFamily,
      Color primaryColor,
      Color bodyTextColor,
      Color cardBackgroundColor,
      Color cardBorderColor,
      Map<String, dynamic> textStyles,
      Map<String, dynamic> layoutStyles) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: (layoutStyles['itemSpacing'] as int?)?.toDouble() ?? 12),
      itemBuilder: (context, index) {
        return _buildMenuItemCard(
          context,
          items[index],
          fontFamily,
          primaryColor,
          bodyTextColor,
          cardBackgroundColor,
          cardBorderColor,
          textStyles,
          padding: (layoutStyles['itemPadding'] as int?)?.toDouble() ?? 16,
          cardImageHeight: (layoutStyles['cardImage']?['height'] as int?)?.toDouble() ?? 80,
          cardImageWidth: (layoutStyles['cardImage']?['width'] as int?)?.toDouble() ?? 80,
        );
      },
    );
  }

  Widget _buildItemsGrid(
      BuildContext context,
      List<dynamic> items,
      String fontFamily,
      Color primaryColor,
      Color bodyTextColor,
      Color cardBackgroundColor,
      Color cardBorderColor,
      Map<String, dynamic> textStyles,
      Map<String, dynamic> layoutStyles) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layoutStyles['crossAxisCount'] ?? 2,
        crossAxisSpacing: (layoutStyles['crossAxisSpacing'] as int?)?.toDouble() ?? 16.0,
        mainAxisSpacing: (layoutStyles['mainAxisSpacing'] as int?)?.toDouble() ?? 16.0,
        childAspectRatio: layoutStyles['childAspectRatio']?.toDouble() ?? 0.8,
      ),
      itemBuilder: (context, index) {
        return _buildMenuItemCard(
          context,
          items[index],
          fontFamily,
          primaryColor,
          bodyTextColor,
          cardBackgroundColor,
          cardBorderColor,
          textStyles,
          padding: (layoutStyles['itemPadding'] as int?)?.toDouble() ?? 8,
          isGrid: true,
        );
      },
    );
  }

  Widget _buildMenuItemCard(
      BuildContext context,
      Map<String, dynamic> itemData,
      String fontFamily,
      Color primaryColor,
      Color bodyTextColor,
      Color cardBackgroundColor,
      Color cardBorderColor,
      Map<String, dynamic> textStyles,
      {
        required double padding,
        bool isGrid = false,
        double? cardImageHeight,
        double? cardImageWidth,
      }) {
    final String imageFileName = itemData['imageUrl']?.split('/').last ?? 'placeholder.png';
    final String imageUrl = _getRoomServiceAssetPath(imageFileName);
    final cardBorderRadius = (roomServiceMenu['pageConfig']['layoutStyles']['card']['borderRadius'] as int?)?.toDouble() ?? 8;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomServiceDetailPage(
              product: itemData,
              tenantConfig: tenantConfig,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(cardBorderRadius),
          border: Border.all(color: cardBorderColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: isGrid
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardBorderRadius),
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.fastfood, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              itemData['name'] ?? '',
              style: GoogleFonts.getFont(
                fontFamily,
                fontSize: (textStyles['itemTitle']?['fontSize'] as int?)?.toDouble() ?? 18,
                fontWeight: _getFontWeight(textStyles['itemTitle']?['fontWeight']),
                color: primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'R\$ ${itemData['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: GoogleFonts.getFont(
                fontFamily,
                fontSize: (textStyles['itemPrice']?['fontSize'] as int?)?.toDouble() ?? 16,
                fontWeight: _getFontWeight(textStyles['itemPrice']?['fontWeight']),
                color: primaryColor,
              ),
            ),
          ],
        )
            : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(cardBorderRadius),
              child: Image.asset(
                imageUrl,
                height: cardImageHeight,
                width: cardImageWidth,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: cardImageHeight,
                    width: cardImageWidth,
                    color: Colors.grey[200],
                    child: Icon(Icons.fastfood, color: Colors.grey[400]),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemData['name'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: primaryColor,
                      fontSize: (textStyles['itemTitle']?['fontSize'] as int?)?.toDouble() ?? 18,
                      fontWeight: _getFontWeight(textStyles['itemTitle']?['fontWeight']),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemData['description'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: bodyTextColor,
                      fontSize: (textStyles['itemDescription']?['fontSize'] as int?)?.toDouble() ?? 14,
                      fontWeight: _getFontWeight(textStyles['itemDescription']?['fontWeight']),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${itemData['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: primaryColor,
                      fontSize: (textStyles['itemPrice']?['fontSize'] as int?)?.toDouble() ?? 16,
                      fontWeight: _getFontWeight(textStyles['itemPrice']?['fontWeight']),
                    ),
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