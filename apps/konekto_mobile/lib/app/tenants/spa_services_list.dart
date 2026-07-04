import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'spa_detail_page.dart';

class SpaServicesList extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final Map<String, dynamic> spaServicesData;

  const SpaServicesList({
    super.key,
    required this.tenantConfig,
    required this.spaServicesData,
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
      default:
        return FontWeight.w400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageConfig = spaServicesData['pageConfig'] ?? {};
    final spaServices = spaServicesData['spaServices'] ?? [];
    
    // Obtendo o tipo de layout do JSON
    final String layoutType = pageConfig['layoutType'] ?? 'list';

    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(tenantConfig['colorPalette']['background']);
    final Color bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    
    final spaStyles = pageConfig['styles'] ?? {};
    final spaTextStyles = pageConfig['textStyles'] ?? {};
    final Color cardBackgroundColor = hexToColor(spaStyles['cardBackgroundColor'] ?? tenantConfig['colorPalette']['cardBackground']);
    
    final String pageTitle = pageConfig['title'] ?? 'SPA e Bem-Estar';
    final String bannerImageUrl = pageConfig['bannerImageUrl'] ?? "assets/app_assets/images/placeholder.png";

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          fontSize: (spaTextStyles['pageTitle']?['fontSize'] as int?)?.toDouble() ?? 24,
                          fontWeight: _getFontWeight(spaTextStyles['pageTitle']?['fontWeight']),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      bannerImageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/app_assets/images/placeholder.png',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Serviços Disponíveis',
                  style: GoogleFonts.getFont(
                    fontFamily,
                    color: primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                // Renderização condicional baseada no layoutType do JSON
                if (spaServices.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (layoutType == 'grid')
                  _buildServiceGrid(context, spaServices, primaryColor, bodyTextColor, fontFamily, cardBackgroundColor, tenantConfig, spaTextStyles)
                else
                  _buildServiceList(context, spaServices, primaryColor, bodyTextColor, fontFamily, cardBackgroundColor, tenantConfig, spaTextStyles),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceList(BuildContext context, List<dynamic> services, Color primaryColor, Color bodyTextColor, String fontFamily, Color cardBackgroundColor, Map<String, dynamic> tenantConfig, Map<String, dynamic> textStyles) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: services.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildServiceCard(context, services[index], primaryColor, bodyTextColor, fontFamily, cardBackgroundColor, tenantConfig, textStyles);
      },
    );
  }

  Widget _buildServiceGrid(BuildContext context, List<dynamic> services, Color primaryColor, Color bodyTextColor, String fontFamily, Color cardBackgroundColor, Map<String, dynamic> tenantConfig, Map<String, dynamic> textStyles) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.8, // Ajuste o aspect ratio para o layout da grade
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(context, services[index], primaryColor, bodyTextColor, fontFamily, cardBackgroundColor, tenantConfig, textStyles, isGrid: true);
      },
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    Map<String, dynamic> service,
    Color primaryColor,
    Color bodyTextColor,
    String fontFamily,
    Color cardBackgroundColor,
    Map<String, dynamic> tenantConfig,
    Map<String, dynamic> textStyles, {
    bool isGrid = false,
  }) {
    final serviceTitle = service['title'] ?? service['name'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpaDetailPage(
              tenantConfig: tenantConfig,
              service: service,
            ),
          ),
        );
      },
      child: Container(
        padding: isGrid ? const EdgeInsets.all(8) : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: isGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.asset(
                        service['imageUrl'] ?? 'assets/app_assets/images/placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.black54),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceTitle,
                          style: GoogleFonts.getFont(
                            fontFamily,
                            fontSize: (textStyles['itemTitle']?['fontSize'] as int?)?.toDouble() ?? 18,
                            fontWeight: _getFontWeight(textStyles['itemTitle']?['fontWeight']),
                            color: primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['description'] ?? '',
                          style: GoogleFonts.getFont(
                            fontFamily,
                            fontSize: (textStyles['itemDescription']?['fontSize'] as int?)?.toDouble() ?? 14,
                            fontWeight: _getFontWeight(textStyles['itemDescription']?['fontWeight']),
                            color: bodyTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${service['price']?.toStringAsFixed(2) ?? '0.00'}',
                          style: GoogleFonts.getFont(
                            fontFamily,
                            fontSize: (textStyles['itemPrice']?['fontSize'] as int?)?.toDouble() ?? 16,
                            fontWeight: _getFontWeight(textStyles['itemPrice']?['fontWeight']),
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service['imageUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        service['imageUrl'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
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
                          serviceTitle,
                          style: GoogleFonts.getFont(
                            fontFamily,
                            color: primaryColor,
                            fontSize: (textStyles['itemTitle']?['fontSize'] as int?)?.toDouble() ?? 18,
                            fontWeight: _getFontWeight(textStyles['itemTitle']?['fontWeight']),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service['description'] ?? '',
                          style: GoogleFonts.getFont(
                            fontFamily,
                            color: bodyTextColor,
                            fontSize: (textStyles['itemDescription']?['fontSize'] as int?)?.toDouble() ?? 14,
                            fontWeight: _getFontWeight(textStyles['itemDescription']?['fontWeight']),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${service['price']?.toStringAsFixed(2) ?? '0.00'}',
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