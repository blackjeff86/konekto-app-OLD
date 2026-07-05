import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/app/tenants/service_items_list_page.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';
import 'package:konekto/models/service.dart' as models;

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

/// Ícones conhecidos pro `Service.icon` (string) vindo da API — mesmo
/// conjunto oferecido no portal (`service_icons.dart`), mais alguns legados
/// (map/book_online) que ainda aparecem em `navigationItems`.
const Map<String, IconData> _iconMapping = {
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
  'pedal_bike': Icons.pedal_bike,
  'local_laundry_service': Icons.local_laundry_service,
  'pool': Icons.pool,
  'fitness_center': Icons.fitness_center,
  'local_bar': Icons.local_bar,
  'directions_car': Icons.directions_car,
  'celebration': Icons.celebration,
  'local_shipping': Icons.local_shipping,
  'pets': Icons.pets,
  'child_care': Icons.child_care,
};

/// Lista de serviços do hotel — busca `GET /services` (dinâmico, definido
/// pelo hotel no portal) em vez de ler um `servicesList` fixo do
/// `tenant_config.json`. Cada card leva pra [ServiceItemsListPage].
class ServicesPage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;

  ServicesPage({super.key, required this.tenantConfig});

  final TenantRepository _repository = createTenantRepository();

  String get _hotelId => tenantConfig['id'] ?? 'hotel_1';

  Future<({Map<String, dynamic> pageConfig, List<models.Service> services})> _load() async {
    final pageConfig = await _repository.getServicesPageConfig(_hotelId);
    final rawServices = await _repository.getServices(_hotelId);
    final services = rawServices.map((raw) => models.Service.fromJson(raw as Map<String, dynamic>)).toList();
    return (pageConfig: pageConfig, services: services);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({Map<String, dynamic> pageConfig, List<models.Service> services})>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Erro ao carregar os serviços.')));
        }

        final pageConfig = snapshot.data!.pageConfig;
        final services = snapshot.data!.services;
        final pageStyles = pageConfig['pageStyles'];
        final cardStyles = pageConfig['cardStyles'];

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
                    Text(
                      (tenantConfig['navigationItems'] as List<dynamic>).firstWhere(
                            (item) => item['route'] == 'services',
                            orElse: () => {'label': 'Serviços'},
                          )['label'] ??
                          'Serviços',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 24, fontWeight: FontWeight.w700),
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
                          pageStyles['banner']['imageUrl'] ?? 'assets/app_assets/images/placeholder.png',
                          height: pageStyles['banner']['height']?.toDouble() ?? 150.0,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/app_assets/images/placeholder.png',
                            height: pageStyles['banner']['height']?.toDouble() ?? 150.0,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
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
                    if (services.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Nenhum serviço disponível no momento.',
                          style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 14),
                        ),
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: services.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _ServiceCard(
                          service: services[index],
                          cardStyles: cardStyles,
                          tenantConfig: tenantConfig,
                          fontFamily: fontFamily,
                          primaryColor: primaryColor,
                          bodyTextColor: bodyTextColor,
                          cardBackgroundColor: cardBackgroundColor,
                          cardBorderColor: cardBorderColor,
                        ),
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
}

class _ServiceCard extends StatelessWidget {
  final models.Service service;
  final Map<String, dynamic> cardStyles;
  final Map<String, dynamic> tenantConfig;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;

  const _ServiceCard({
    required this.service,
    required this.cardStyles,
    required this.tenantConfig,
    required this.fontFamily,
    required this.primaryColor,
    required this.bodyTextColor,
    required this.cardBackgroundColor,
    required this.cardBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconMapping[service.icon] ?? Icons.miscellaneous_services;
    final iconContainerStyles = cardStyles['iconContainer'];
    final titleStyles = cardStyles['title'];
    final descriptionStyles = cardStyles['description'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceItemsListPage(tenantConfig: tenantConfig, serviceId: service.id),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: cardStyles['padding']?.toDouble() ?? 16.0, vertical: 12),
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
              child: Icon(icon, size: iconContainerStyles['iconSize']?.toDouble() ?? 24.0, color: primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
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
                    service.description,
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
