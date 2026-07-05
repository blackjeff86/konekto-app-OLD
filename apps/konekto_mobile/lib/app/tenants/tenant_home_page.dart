import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/app/tenants/services_page.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';

// --- Modelos de dados atualizados para refletir a nova estrutura JSON ---
class HotelInfo {
  final String name;
  final String logoUrl;
  final Map<String, dynamic>? promoImages;

  HotelInfo({required this.name, required this.logoUrl, this.promoImages});

  factory HotelInfo.fromJson(Map<String, dynamic> json) {
    return HotelInfo(
      name: json['name'],
      logoUrl: json['logoUrl'],
      promoImages: json['promoImages'],
    );
  }
}

class TenantConfig {
  final HotelInfo hotelInfo;
  final Map<String, dynamic> colorPalette;
  final Map<String, dynamic> typography;
  final Map<String, dynamic> homePage;
  final Map<String, dynamic> buttonStyles;
  final List<dynamic> navigationItems;
  final List<dynamic> servicesList;

  TenantConfig({
    required this.hotelInfo,
    required this.colorPalette,
    required this.typography,
    required this.homePage,
    required this.buttonStyles,
    required this.navigationItems,
    required this.servicesList,
  });

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    return TenantConfig(
      hotelInfo: HotelInfo.fromJson(json['hotelInfo']),
      colorPalette: json['colorPalette'],
      typography: json['typography'],
      homePage: json['homePage'],
      buttonStyles: json['buttonStyles'],
      navigationItems: json['navigationItems'],
      servicesList: json['servicesList'] ?? [],
    );
  }
}

class TenantHomePage extends StatefulWidget {
  final String tenantId;
  const TenantHomePage({super.key, required this.tenantId});

  @override
  State<TenantHomePage> createState() => _TenantHomePageState();
}

class _TenantHomePageState extends State<TenantHomePage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _dataFuture;
  late final Map<String, Widget Function(Map<String, dynamic>, List<dynamic>?)> _widgetMapping;
  final TenantRepository _repository = createTenantRepository();

  final Map<String, IconData> _iconMapping = {
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
    'door_front_door_outlined': Icons.door_front_door_outlined,
    'person_pin': Icons.person_pin,
    'wifi': Icons.wifi,
    'lock': Icons.lock,
  };

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadTenantData();
  }

  Future<Map<String, dynamic>> _loadTenantData() async {
    final Map<String, dynamic> tenantConfigMap = await _repository.getTenantConfig(widget.tenantId);
    final Map<String, dynamic> guestInfoMap = await _repository.getGuestInfo(widget.tenantId);

    _widgetMapping = {
      'home': (data, _) {
        final guestData = data['guestInfo']['guest'];
        final wifiData = data['guestInfo']['wifi'];
        return TenantHomeBody(
          tenantId: widget.tenantId,
          userName: guestData['name'] ?? 'Hóspede',
          roomNumber: guestData['room_number'] ?? 'N/A',
          wifiNetworkName: wifiData['network_name'] ?? 'Não disponível',
          wifiPassword: wifiData['password'] ?? 'Não disponível',
          tenantConfig: data['tenantConfig'],
          iconMapping: _iconMapping,
        );
      },
      'services': (data, _) => ServicesPage(
        tenantConfig: data['tenantConfig'],
      ),
      'bookings': (data, _) => BookingsPage(
        tenantConfig: data['tenantConfig'],
        onExploreServices: () => _navigateToRoute(data, 'services'),
      ),
      'profile': (data, _) => ProfilePage(
        tenantConfig: data['tenantConfig'],
        guestInfo: data['guestInfo'],
        onEndSession: () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    };

    return {
      'tenantConfig': tenantConfigMap,
      'guestInfo': guestInfoMap,
    };
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToRoute(Map<String, dynamic> data, String route) {
    final config = TenantConfig.fromJson(data['tenantConfig']);
    final index = config.navigationItems.indexWhere((item) => item['route'] == route);
    if (index != -1) {
      _onItemTapped(index);
    }
  }

  Widget _getWidgetForIndex(int index, Map<String, dynamic> data) {
    final config = TenantConfig.fromJson(data['tenantConfig']);
    final navItem = config.navigationItems[index];
    final route = navItem['route'];
    final widgetBuilder = _widgetMapping[route];
    if (widgetBuilder != null) {
      return widgetBuilder(data, data['roomServiceMenu']);
    }
    return const Center(child: Text('Tela não encontrada'));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFFF8),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Erro ao carregar dados: ${snapshot.error}'),
            ),
          );
        } else {
          final data = snapshot.data!;
          final config = TenantConfig.fromJson(data['tenantConfig']);
          final Color primaryColor = hexToColor(config.colorPalette['primary']);
          final Color secondaryColor = hexToColor(config.colorPalette['secondary']);
          final Color backgroundColor = hexToColor(config.colorPalette['background']);

          return Scaffold(
            backgroundColor: backgroundColor,
            body: _getWidgetForIndex(_selectedIndex, data),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: secondaryColor,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: List.generate(config.navigationItems.length, (index) {
                final item = config.navigationItems[index];
                final icon = _iconMapping[item['icon']] ?? Icons.error;
                return BottomNavigationBarItem(
                  icon: Icon(icon),
                  label: item['label'],
                );
              }),
            ),
          );
        }
      },
    );
  }
}

// Funções auxiliares para leitura de dados
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

class TenantHomeBody extends StatelessWidget {
  final String tenantId;
  final String userName;
  final String roomNumber;
  final String wifiNetworkName;
  final String wifiPassword;
  final Map<String, dynamic> tenantConfig;
  final Map<String, IconData> iconMapping;

  const TenantHomeBody({
    super.key,
    required this.tenantId,
    required this.userName,
    required this.roomNumber,
    required this.wifiNetworkName,
    required this.wifiPassword,
    required this.tenantConfig,
    required this.iconMapping,
  });

  @override
  Widget build(BuildContext context) {
    final homePageConfig = tenantConfig['homePage'];
    final welcomeSectionConfig = homePageConfig['welcomeSection'];
    final roomDetailsConfig = homePageConfig['roomDetailsSection'];
    final quickServicesConfig = homePageConfig['quickServicesSection'];
    final homeTextStyles = homePageConfig['textStyles'];

    final hotelName = tenantConfig['hotelInfo']['name'];
    final promoImages = tenantConfig['hotelInfo']['promoImages']['images'];
    final primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);
    final fontFamily = tenantConfig['typography']['fontFamily'];
    
    // Novas variáveis para ler os estilos do JSON
    final pageTitleStyle = homeTextStyles['pageTitle'];
    final welcomeTitleStyle = homeTextStyles['welcomeTitle'];
    final welcomeMessageStyle = homeTextStyles['welcomeMessage'];
    final quickServicesTitleStyle = homeTextStyles['quickServicesTitle'];
    final carouselHeight = tenantConfig['hotelInfo']['promoImages']['carouselHeight']?.toDouble() ?? 250;


    return SafeArea(
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 48.0),
                      child: Text(
                        hotelName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.getFont(
                          fontFamily,
                          fontSize: pageTitleStyle['size']?.toDouble() ?? 24,
                          fontWeight: _getFontWeight(pageTitleStyle['weight']),
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: primaryColor.withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(iconMapping['person'], color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ImageCarousel(imageUrls: List<String>.from(promoImages), height: carouselHeight),
              const SizedBox(height: 20),
              Text(
                welcomeSectionConfig['titleTemplate'].replaceAll('{userName}', userName),
                style: GoogleFonts.getFont(
                  fontFamily,
                  fontSize: welcomeTitleStyle['size']?.toDouble() ?? 24,
                  fontWeight: _getFontWeight(welcomeTitleStyle['weight']),
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                welcomeSectionConfig['message'],
                style: GoogleFonts.getFont(
                  fontFamily,
                  fontSize: welcomeMessageStyle['size']?.toDouble() ?? 16,
                  fontWeight: _getFontWeight(welcomeMessageStyle['weight']),
                  color: bodyTextColor,
                ),
              ),
              const SizedBox(height: 24),
              if (roomDetailsConfig['enabled'] == true)
                ExpandableCard(
                  roomNumber: roomNumber,
                  wifiNetworkName: wifiNetworkName,
                  wifiPassword: wifiPassword,
                  tenantConfig: tenantConfig,
                  iconMapping: iconMapping,
                ),
              const SizedBox(height: 24),
              Text(
                quickServicesConfig['title'],
                style: GoogleFonts.getFont(
                  fontFamily,
                  fontSize: quickServicesTitleStyle['size']?.toDouble() ?? 18,
                  fontWeight: _getFontWeight(quickServicesTitleStyle['weight']),
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(quickServicesConfig['items'].length, (index) {
                  final card = quickServicesConfig['items'][index];
                  return _buildServiceCard(
                    context,
                    title: card['title'],
                    iconName: card['icon'],
                    iconMapping: iconMapping,
                    tenantConfig: tenantConfig,
                    cardStyle: quickServicesConfig['card']['style'],
                    titleStyle: quickServicesConfig['card']['titleStyle'],
                    iconStyle: quickServicesConfig['card']['iconStyle'],
                  );
                }),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // O resto da classe TenantHomeBody permanece inalterado
  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String iconName,
    required Map<String, IconData> iconMapping,
    required Map<String, dynamic> tenantConfig,
    required Map<String, dynamic> cardStyle,
    required Map<String, dynamic> titleStyle,
    required Map<String, dynamic> iconStyle,
  }) {
    final icon = iconMapping[iconName] ?? Icons.error;
    final fontFamily = tenantConfig['typography']['fontFamily'];
    final cardBackgroundColor = hexToColor(cardStyle['backgroundColor']);
    final cardBorderColor = hexToColor(cardStyle['borderColor']);
    final iconColor = hexToColor(iconStyle['color']);
    final titleColor = hexToColor(titleStyle['color']);

    final double iconSize = iconStyle['size']?.toDouble() ?? 24;

    return Container(
      width: (MediaQuery.of(context).size.width - 32 - 24) / 2,
      height: cardStyle['height']?.toDouble() ?? 132,
      padding: EdgeInsets.all(cardStyle['padding']?.toDouble() ?? 16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        border: Border.all(color: cardBorderColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(cardStyle['borderRadius']?.toDouble() ?? 8),
        boxShadow: [
          BoxShadow(color: iconColor.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize + 20,
            height: iconSize + 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.getFont(
              fontFamily,
              fontSize: titleStyle['size']?.toDouble() ?? 16,
              fontWeight: _getFontWeight(titleStyle['weight']),
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableCard extends StatefulWidget {
  final String roomNumber;
  final String wifiNetworkName;
  final String wifiPassword;
  final Map<String, dynamic> tenantConfig;
  final Map<String, IconData> iconMapping;

  const ExpandableCard({
    Key? key,
    required this.roomNumber,
    required this.wifiNetworkName,
    required this.wifiPassword,
    required this.tenantConfig,
    required this.iconMapping,
  }) : super(key: key);

  @override
  _ExpandableCardState createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final homePageConfig = widget.tenantConfig['homePage'];
    final roomDetailsConfig = homePageConfig['roomDetailsSection'];
    final styles = roomDetailsConfig['styles'];
    final icons = styles['icons'];
    final homeTextStyles = homePageConfig['textStyles'];

    final fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final bodyTextColor = hexToColor(widget.tenantConfig['typography']['bodyText']['color']);
    final cardBackgroundColor = hexToColor(styles['backgroundColor']);
    final cardBorderColor = hexToColor(styles['borderColor']);
    
    // Novas variáveis para ler os estilos do JSON
    final cardTitleStyle = homeTextStyles['roomCardTitle'];
    final cardDetailsStyle = homeTextStyles['roomCardDetails'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: primaryColor.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.10),
                      ),
                      child: Icon(widget.iconMapping[roomDetailsConfig['icon']], color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      roomDetailsConfig['title'],
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: primaryColor,
                        fontSize: cardTitleStyle['size']?.toDouble() ?? 16,
                        fontWeight: _getFontWeight(cardTitleStyle['weight']),
                      ),
                    ),
                  ],
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            Divider(color: cardBorderColor),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: widget.iconMapping[icons['roomIcon']]!,
              text: 'Quarto: ${widget.roomNumber}',
              fontFamily: fontFamily,
              color: bodyTextColor,
              iconColor: primaryColor,
              fontSize: cardDetailsStyle['size']?.toDouble() ?? 16,
              fontWeight: _getFontWeight(cardDetailsStyle['weight']),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: widget.iconMapping[icons['wifiIcon']]!,
              text: 'Rede Wi-Fi: ${widget.wifiNetworkName}',
              fontFamily: fontFamily,
              color: bodyTextColor,
              iconColor: primaryColor,
              fontSize: cardDetailsStyle['size']?.toDouble() ?? 16,
              fontWeight: _getFontWeight(cardDetailsStyle['weight']),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: widget.iconMapping[icons['passwordIcon']]!,
              text: 'Senha: ${widget.wifiPassword}',
              fontFamily: fontFamily,
              color: bodyTextColor,
              iconColor: primaryColor,
              fontSize: cardDetailsStyle['size']?.toDouble() ?? 16,
              fontWeight: _getFontWeight(cardDetailsStyle['weight']),
            ),
          ],
        ],
      ),
    );
  }

  // O _buildDetailRow agora aceita argumentos para tamanho e peso da fonte
  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required String fontFamily,
    required Color color,
    required Color iconColor,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.getFont(
            fontFamily,
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }
}

// O ImageCarousel agora recebe a altura do JSON
class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const ImageCarousel({Key? key, required this.imageUrls, required this.height}) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Image.asset(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text('Erro ao carregar imagem', textAlign: TextAlign.center),
                    ),
                  );
                },
              );
            },
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

class BookingsPage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final VoidCallback? onExploreServices;

  const BookingsPage({super.key, required this.tenantConfig, this.onExploreServices});

  @override
  Widget build(BuildContext context) {
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final Color bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withValues(alpha: 0.10)),
              child: Icon(Icons.event_note_rounded, size: 44, color: primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma reserva por enquanto',
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas reservas de spa, restaurantes e passeios vão aparecer aqui assim que forem confirmadas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(fontFamily, fontSize: 14, color: bodyTextColor, height: 1.4),
            ),
            const SizedBox(height: 28),
            if (onExploreServices != null)
              ElevatedButton.icon(
                onPressed: onExploreServices,
                icon: const Icon(Icons.explore_outlined),
                label: Text('Explorar Serviços', style: GoogleFonts.getFont(fontFamily, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final Map<String, dynamic>? guestInfo;
  final VoidCallback? onEndSession;

  const ProfilePage({super.key, required this.tenantConfig, this.guestInfo, this.onEndSession});

  @override
  Widget build(BuildContext context) {
    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(tenantConfig['colorPalette']['primary']);
    final Color bodyTextColor = hexToColor(tenantConfig['typography']['bodyText']['color']);
    final Color cardBackgroundColor = hexToColor(tenantConfig['colorPalette']['cardBackground']);
    final String hotelName = tenantConfig['hotelInfo']?['name'] ?? '';

    final Map<String, dynamic> guest = guestInfo?['guest'] ?? {};
    final String guestName = guest['name'] ?? 'Hóspede';
    final String roomNumber = guest['room_number'] ?? 'N/A';
    final String initials = guestName.trim().isNotEmpty
        ? guestName.trim().split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase()
        : '?';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.getFont(fontFamily, color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              guestName,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              hotelName,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: primaryColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withValues(alpha: 0.10)),
                    child: Icon(Icons.meeting_room_outlined, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quarto', style: GoogleFonts.getFont(fontFamily, color: bodyTextColor, fontSize: 13)),
                      Text(
                        roomNumber,
                        style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (onEndSession != null)
              OutlinedButton.icon(
                onPressed: onEndSession,
                icon: Icon(Icons.logout_rounded, color: primaryColor),
                label: Text('Encerrar Sessão', style: GoogleFonts.getFont(fontFamily, color: primaryColor, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}