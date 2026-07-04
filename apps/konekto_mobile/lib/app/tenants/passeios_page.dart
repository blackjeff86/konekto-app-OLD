import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'passeios_detail_page.dart';

// Função auxiliar para converter HEX em Color
Color hexToColor(String hexCode) {
  if (hexCode.isEmpty) return Colors.transparent;
  return Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
}

// Função auxiliar para converter weight string em FontWeight
FontWeight getFontWeight(String weight) {
  switch (weight) {
    case 'w100':
      return FontWeight.w100;
    case 'w200':
      return FontWeight.w200;
    case 'w300':
      return FontWeight.w300;
    case 'w400':
    case 'regular':
      return FontWeight.w400;
    case 'w500':
      return FontWeight.w500;
    case 'w600':
      return FontWeight.w600;
    case 'w700':
    case 'bold':
      return FontWeight.w700;
    case 'w800':
      return FontWeight.w800;
    case 'w900':
      return FontWeight.w900;
    default:
      return FontWeight.w400;
  }
}

class PasseiosPage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final Map<String, dynamic> passeiosData;

  const PasseiosPage({
    Key? key,
    required this.tenantConfig,
    required this.passeiosData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> passeios = passeiosData['passeios'] ?? [];

    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color backgroundColor = hexToColor(tenantConfig['colorPalette']['background']);
    final Color pageTitleColor = hexToColor(tenantConfig['typography']['heading1']['color']);
    final Color passeioTitleColor = hexToColor(tenantConfig['typography']['passeioTitle']['color']);
    final Color passeioDescriptionColor = hexToColor(tenantConfig['typography']['passeioDescription']['color']);
    final Color cardBackgroundColor = hexToColor(tenantConfig['colorPalette']['cardBackground']);
    final Color cardShadowColor = hexToColor(tenantConfig['colorPalette']['dividerColor']);
    final Color buttonColor = hexToColor(tenantConfig['buttonStyles']['primaryButton']['backgroundColor']);
    final Color buttonTextColor = hexToColor(tenantConfig['buttonStyles']['primaryButton']['textColor']);

    final double screenPadding = (tenantConfig['layoutStyles']?['screenPadding'] ?? 16).toDouble();
    final double cardPadding = (tenantConfig['layoutStyles']?['card']?['padding'] ?? 16).toDouble();
    final double cardBorderRadius = (tenantConfig['layoutStyles']?['card']?['borderRadius'] ?? 12).toDouble();
    final double itemSpacing = (tenantConfig['layoutStyles']?['itemSpacing'] ?? 16).toDouble();
    final double textSpacing = (tenantConfig['layoutStyles']?['textSpacing'] ?? 4).toDouble();
    final double buttonHeight = (tenantConfig['layoutStyles']?['buttonHeight'] ?? 32).toDouble();
    final double buttonPadding = (tenantConfig['layoutStyles']?['buttonPadding'] ?? 16).toDouble();
    final double buttonBorderRadius = (tenantConfig['layoutStyles']?['buttonBorderRadius'] ?? 16).toDouble();
    
    final String pageTitle = passeiosData['pageConfig']?['title'] ?? 'Passeios';
    // Adicionando o bannerImageUrl
    final String bannerImageUrl = passeiosData['pageConfig']?['bannerImageUrl'] ?? "assets/app_assets/images/placeholder.png";


    if (passeios.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: pageTitleColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            pageTitle,
            style: GoogleFonts.getFont(
              fontFamily,
              color: pageTitleColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'Nenhum passeio encontrado',
            style: GoogleFonts.getFont(
              fontFamily,
              color: passeioDescriptionColor,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: pageTitleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          pageTitle,
          style: GoogleFonts.getFont(
            fontFamily,
            color: pageTitleColor,
            fontSize: 24,
            fontWeight: getFontWeight(tenantConfig['typography']['heading1']['weight'] ?? 'w700'),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView( // Adicionado SingleChildScrollView para o conteúdo rolar
          child: Padding(
            padding: EdgeInsets.all(screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner de imagem
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
                Text(
                  'Explore Nossos Passeios', // Título para a lista de passeios
                  style: GoogleFonts.getFont(
                    fontFamily,
                    color: pageTitleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                // A lista de passeios agora está dentro de um Expanded, que precisa de um pai com altura definida,
                // ou o SingleChildScrollView acima já resolve o problema de renderização.
                // Como estamos dentro de um SingleChildScrollView, podemos remover o Expanded e usar a ListView diretamente.
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(), // Impede o ListView de rolar separadamente do SingleChildScrollView
                  shrinkWrap: true, // Faz o ListView ocupar apenas o espaço necessário
                  itemCount: passeios.length,
                  itemBuilder: (context, index) {
                    final passeio = passeios[index];
                    final String imagePath = 'assets/tenant_assets/hotels/${tenantConfig['hotelInfo']['name'].toLowerCase().replaceAll(' ', '_')}/images/passeios/${passeio['imageFileName']}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PasseiosDetailPage(
                              passeio: passeio,
                              tenantConfig: tenantConfig,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: itemSpacing),
                        decoration: BoxDecoration(
                          color: cardBackgroundColor,
                          borderRadius: BorderRadius.circular(cardBorderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: cardShadowColor.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(cardBorderRadius),
                                child: Image.asset(
                                  imagePath,
                                  width: (tenantConfig['layoutStyles']?['passeioImage']?['width'] ?? 130).toDouble(),
                                  height: (tenantConfig['layoutStyles']?['passeioImage']?['height'] ?? 160).toDouble(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: (tenantConfig['layoutStyles']?['passeioImage']?['width'] ?? 130).toDouble(),
                                    height: (tenantConfig['layoutStyles']?['passeioImage']?['height'] ?? 160).toDouble(),
                                    color: Colors.grey[300],
                                    child: Icon(Icons.beach_access, size: 80, color: Colors.grey[500]),
                                  ),
                                ),
                              ),
                              SizedBox(width: itemSpacing),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      passeio['passeioTitle'] ?? '',
                                      style: GoogleFonts.getFont(
                                        fontFamily,
                                        fontSize: (tenantConfig['typography']['passeioTitle']['size'] ?? 16).toDouble(),
                                        fontWeight: getFontWeight(tenantConfig['typography']['passeioTitle']['weight'] ?? 'w700'),
                                        color: passeioTitleColor,
                                      ),
                                    ),
                                    SizedBox(height: textSpacing),
                                    Text(
                                      passeio['description'] ?? '',
                                      style: GoogleFonts.getFont(
                                        fontFamily,
                                        fontSize: (tenantConfig['typography']['passeioDescription']['size'] ?? 14).toDouble(),
                                        fontWeight: getFontWeight(tenantConfig['typography']['passeioDescription']['weight'] ?? 'w400'),
                                        color: passeioDescriptionColor,
                                      ),
                                    ),
                                    SizedBox(height: textSpacing),
                                    if (passeio['location'] != null)
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, color: passeioDescriptionColor, size: 16),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              passeio['location'],
                                              style: GoogleFonts.getFont(
                                                fontFamily,
                                                color: passeioDescriptionColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: itemSpacing),
                                    Container(
                                      height: buttonHeight,
                                      padding: EdgeInsets.symmetric(horizontal: buttonPadding),
                                      decoration: BoxDecoration(
                                        color: buttonColor,
                                        borderRadius: BorderRadius.circular(buttonBorderRadius),
                                      ),
                                      child: Center(
                                        child: Text(
                                          passeio['buttonText'] ?? '',
                                          style: GoogleFonts.getFont(
                                            fontFamily,
                                            fontSize: (tenantConfig['typography']['buttonText']['size'] ?? 14).toDouble(),
                                            fontWeight: getFontWeight(tenantConfig['typography']['buttonText']['weight'] ?? 'w500'),
                                            color: buttonTextColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32), // Espaçamento inferior para o conteúdo
              ],
            ),
          ),
        ),
      ),
    );
  }
}