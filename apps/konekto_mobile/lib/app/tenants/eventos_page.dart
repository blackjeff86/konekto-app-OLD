import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'event_detail_page.dart';

class EventosPage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final Map<String, dynamic> eventosData;

  const EventosPage({
    super.key,
    required this.tenantConfig,
    required this.eventosData,
  });

  Color hexToColor(String hexCode) {
    if (hexCode.isEmpty) {
      return Colors.transparent;
    }
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

  String _getEventAssetPath(String fileName) {
    final String tenantId = tenantConfig['id'] ?? 'hotel_1';
    return 'assets/tenant_assets/hotels/$tenantId/images/eventos/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    final pageConfig = eventosData['pageConfig'] ?? {};
    final eventos = eventosData['eventos'] ?? [];

    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final Color backgroundColor = hexToColor(pageConfig['styles']['backgroundColor'] ?? tenantConfig['colorPalette']['background']);
    final String fontFamily = tenantConfig['typography']['fontFamily'];

    final textStyles = pageConfig['textStyles'] ?? {};
    final layoutStyles = pageConfig['layoutStyles'] ?? {};

    // Adicionando a leitura da URL do banner do JSON
    final String bannerImageUrl = pageConfig['bannerImageUrl'] ?? 'assets/app_assets/images/placeholder.png';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all((layoutStyles['screenPadding'] as int?)?.toDouble() ?? 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        pageConfig['title'] ?? 'Eventos',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.getFont(
                          fontFamily,
                          color: hexToColor(textStyles['pageTitle']['color'] ?? tenantConfig['colorPalette']['primary']),
                          fontSize: (textStyles['pageTitle']['fontSize'] as int?)?.toDouble() ?? 24,
                          fontWeight: _getFontWeight(textStyles['pageTitle']['fontWeight']),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),
                // Adicionando o banner de imagem
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
                const SizedBox(height: 24), // Espaço após o banner
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: (layoutStyles['itemSpacing'] as int?)?.toDouble() ?? 16),
                      child: _buildEventCard(context, evento, pageConfig),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> evento, Map<String, dynamic> pageConfig) {
    final styles = pageConfig['styles'] ?? {};
    final textStyles = pageConfig['textStyles'] ?? {};
    final layoutStyles = pageConfig['layoutStyles'] ?? {};
    final String fontFamily = tenantConfig['typography']['fontFamily'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(
              event: evento,
              tenantConfig: tenantConfig,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((layoutStyles['card']['borderRadius'] as int?)?.toDouble() ?? 12),
        ),
        elevation: (layoutStyles['card']['elevation'] as int?)?.toDouble() ?? 4,
        color: hexToColor(styles['cardBackgroundColor'] ?? '#F5F5F5'),
        child: Padding(
          padding: EdgeInsets.all((layoutStyles['card']['padding'] as int?)?.toDouble() ?? 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento['exclusiveEvent'] ?? '',
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: hexToColor(textStyles['exclusiveEventText']['color'] ?? '#637287'),
                        fontSize: (textStyles['exclusiveEventText']['fontSize'] as int?)?.toDouble() ?? 14,
                        fontWeight: _getFontWeight(textStyles['exclusiveEventText']['fontWeight']),
                      ),
                    ),
                    SizedBox(height: (layoutStyles['textSpacing'] as int?)?.toDouble() ?? 4),
                    Text(
                      evento['title'] ?? '',
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: hexToColor(textStyles['eventTitle']['color'] ?? '#111416'),
                        fontSize: (textStyles['eventTitle']['fontSize'] as int?)?.toDouble() ?? 16,
                        fontWeight: _getFontWeight(textStyles['eventTitle']['fontWeight']),
                      ),
                    ),
                    SizedBox(height: (layoutStyles['textSpacing'] as int?)?.toDouble() ?? 8),
                    Text(
                      evento['description'] ?? '',
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: hexToColor(textStyles['eventDescription']['color'] ?? '#637287'),
                        fontSize: (textStyles['eventDescription']['fontSize'] as int?)?.toDouble() ?? 14,
                        fontWeight: _getFontWeight(textStyles['eventDescription']['fontWeight']),
                      ),
                    ),
                    SizedBox(height: (layoutStyles['textSpacing'] as int?)?.toDouble() ?? 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailPage(
                              event: evento,
                              tenantConfig: tenantConfig,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hexToColor(styles['buttonColor'] ?? '#EFF2F4'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular((layoutStyles['buttonBorderRadius'] as int?)?.toDouble() ?? 16),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: (layoutStyles['buttonPadding'] as int?)?.toDouble() ?? 16),
                        fixedSize: Size.fromHeight((layoutStyles['buttonHeight'] as int?)?.toDouble() ?? 32),
                      ),
                      child: Text(
                        evento['buttonText'] ?? '',
                        style: GoogleFonts.getFont(
                          fontFamily,
                          color: hexToColor(textStyles['buttonText']['color'] ?? '#111416'),
                          fontSize: (textStyles['buttonText']['fontSize'] as int?)?.toDouble() ?? 14,
                          fontWeight: _getFontWeight(textStyles['buttonText']['fontWeight']),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: (layoutStyles['screenPadding'] as int?)?.toDouble() ?? 16),
              ClipRRect(
                borderRadius: BorderRadius.circular((layoutStyles['eventImage']['borderRadius'] as int?)?.toDouble() ?? 12),
                child: Image.asset(
                  _getEventAssetPath(evento['imageFileName'] ?? 'placeholder.png'),
                  width: (layoutStyles['eventImage']['width'] as int?)?.toDouble() ?? 130,
                  height: (layoutStyles['eventImage']['height'] as int?)?.toDouble() ?? 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      SizedBox(
                    width: (layoutStyles['eventImage']['width'] as int?)?.toDouble() ?? 130,
                    height: (layoutStyles['eventImage']['height'] as int?)?.toDouble() ?? 160,
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}