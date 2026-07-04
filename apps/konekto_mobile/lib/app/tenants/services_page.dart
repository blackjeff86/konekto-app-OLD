import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'room_service_page.dart';
import 'spa_services_list.dart';
import 'restaurant_list_page.dart';
import 'passeios_page.dart';
import 'eventos_page.dart';
import 'mapa_page.dart'; // NOVO: Importa a página do mapa
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';

// Importe a função auxiliar
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
    case 'bold': // Adicionado para compatibilidade com "bold"
      return FontWeight.bold;
    default:
      return FontWeight.w400;
  }
}

class ServicesPage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;

  final Map<String, IconData> iconMapping = {
    'home': Icons.home,
    'history': Icons.history,
    'person': Icons.person,
    'settings': Icons.settings,
    'restaurant': Icons.restaurant,
    'spa': Icons.spa,
    'sports_soccer': Icons.sports_soccer,
    'event': Icons.event,
    'widgets': Icons.widgets,
    'room_service': Icons.room_service,
    'map': Icons.map,
    'book_online': Icons.book_online,
  };

  ServicesPage({
    super.key,
    required this.tenantConfig,
  });

  final TenantRepository _repository = createTenantRepository();

  final Map<String, Future<Map<String, dynamic>> Function(TenantRepository, String)> _dataLoaders = {
    'room_service': (repository, hotelId) => repository.getRoomServiceMenu(hotelId),
    'spa': (repository, hotelId) => repository.getSpaServices(hotelId),
    'restaurants': (repository, hotelId) => repository.getRestaurants(hotelId),
    'eventos': (repository, hotelId) => repository.getEventos(hotelId),
    'passeios': (repository, hotelId) => repository.getPasseios(hotelId),
    'mapa': (repository, hotelId) => repository.getMapaData(hotelId),
  };

  final Map<String, Widget Function(Map<String, dynamic>, dynamic)> _pageMapping = {
    'room_service': (tenantConfig, data) => RoomServicePage(
      tenantConfig: tenantConfig,
      roomServiceMenu: data,
    ),
    'spa': (tenantConfig, data) => SpaServicesList(
      tenantConfig: tenantConfig,
      spaServicesData: data,
    ),
    'restaurants': (tenantConfig, data) => RestaurantListPage(
      tenantConfig: tenantConfig,
      restaurantsData: data,
    ),
    'eventos': (tenantConfig, data) => EventosPage(
      tenantConfig: tenantConfig,
      eventosData: data,
    ),
    'passeios': (tenantConfig, data) => PasseiosPage(
      tenantConfig: tenantConfig,
      passeiosData: data,
    ),
    'mapa': (tenantConfig, data) => MapaPage(
      tenantConfig: tenantConfig,
      pageData: data,
    ),
  };

  Future<void> _handleNavigation(BuildContext context, Map<String, dynamic> serviceInfo) async {
    final String? route = serviceInfo['route'];

    if (route == null || !_pageMapping.containsKey(route)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço não implementado ou rota inválida.'),
        ),
      );
      return;
    }

    try {
      dynamic serviceData;
      final loader = _dataLoaders[route];
      if (loader != null) {
        final String hotelId = tenantConfig['id'] ?? 'hotel_1';
        serviceData = await loader(_repository, hotelId);
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _pageMapping[route]!(tenantConfig, serviceData),
        ),
      );
    } catch (e) {
      print('Erro ao carregar os dados para o serviço $route: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os detalhes do serviço.'),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _loadServicesPageConfig() {
    final String hotelId = tenantConfig['id'] ?? 'hotel_1';
    return _repository.getServicesPageConfig(hotelId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadServicesPageConfig(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Erro ao carregar a configuração da página.')),
          );
        }

        final servicesPageConfig = snapshot.data!;
        final pageStyles = servicesPageConfig['pageStyles'];
        final cardStyles = servicesPageConfig['cardStyles'];

        final List<dynamic> servicesList = tenantConfig['servicesList'] ?? [];
        final String fontFamily = tenantConfig['typography']['fontFamily'];
        final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
        final Color backgroundColor = hexToColor(tenantConfig['colorPalette']['background']);
        final Color bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);
        final Color cardBackgroundColor = hexToColor(tenantConfig['colorPalette']['cardBackground']);
        final Color cardBorderColor = hexToColor(tenantConfig['colorPalette']['dividerColor']);

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: Text(
                            tenantConfig['navigationItems'].firstWhere((item) => item['route'] == 'services')['label'] ?? 'Serviços',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.getFont(
                              fontFamily,
                              color: primaryColor,
                              fontSize: 24, // Este valor ainda é fixo, mas poderia ser de um `textStyles` global ou da homePage
                              fontWeight: FontWeight.w700, // Idem
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(pageStyles['banner']['borderRadius']?.toDouble() ?? 16.0),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(pageStyles['banner']['borderRadius']?.toDouble() ?? 16.0),
                        child: Image.asset(
                          pageStyles['banner']['imageUrl'] ?? "assets/app_assets/images/placeholder.png",
                          height: pageStyles['banner']['height']?.toDouble() ?? 150.0,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/app_assets/images/placeholder.png',
                              height: pageStyles['banner']['height']?.toDouble() ?? 150.0,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      pageStyles['pageTitle']['text'] ?? 'Serviços Disponíveis',
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: primaryColor,
                        fontSize: pageStyles['pageTitle']['size']?.toDouble() ?? 24.0,
                        fontWeight: _getFontWeight(pageStyles['pageTitle']['weight']),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: servicesList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final cardData = servicesList[index];
                        return _buildServiceCard(
                          context,
                          cardData,
                          cardStyles,
                          iconMapping,
                          tenantConfig,
                          fontFamily,
                          primaryColor,
                          bodyTextColor,
                          cardBackgroundColor,
                          cardBorderColor,
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    Map<String, dynamic> cardData,
    Map<String, dynamic> cardStyles,
    Map<String, IconData> iconMapping,
    Map<String, dynamic> tenantConfig,
    String fontFamily,
    Color primaryColor,
    Color bodyTextColor,
    Color cardBackgroundColor,
    Color cardBorderColor,
  ) {
    final icon = iconMapping[cardData['icon']] ?? Icons.error;
    final iconContainerStyles = cardStyles['iconContainer'];
    final titleStyles = cardStyles['title'];
    final descriptionStyles = cardStyles['description'];

    return GestureDetector(
      onTap: () {
        _handleNavigation(context, cardData);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: cardStyles['padding']?.toDouble() ?? 16.0,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(cardStyles['borderRadius']?.toDouble() ?? 8.0),
          border: Border.all(color: cardBorderColor.withValues(alpha: 0.4), width: cardStyles['borderWidth']?.toDouble() ?? 1.0),
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconContainerStyles['size']?.toDouble() ?? 48.0,
              height: iconContainerStyles['size']?.toDouble() ?? 48.0,
              decoration: ShapeDecoration(
                color: primaryColor.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(iconContainerStyles['borderRadius']?.toDouble() ?? 8.0)),
              ),
              child: Icon(
                icon,
                size: iconContainerStyles['iconSize']?.toDouble() ?? 24.0,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cardData['title'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: primaryColor,
                      fontSize: titleStyles['size']?.toDouble() ?? 16.0,
                      fontWeight: _getFontWeight(titleStyles['weight']),
                      height: 1.50,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cardData['description'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: bodyTextColor,
                      fontSize: descriptionStyles['size']?.toDouble() ?? 14.0,
                      fontWeight: _getFontWeight(descriptionStyles['weight']),
                      height: 1.50,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: primaryColor.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}