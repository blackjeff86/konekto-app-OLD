import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'welcome_screen.dart';
import '../utils/app_theme_data.dart';
import 'dart:math';
import 'dart:async';
import '../widgets/bottom_nav_bar.dart';

enum ScreenStatus { input, loading, error }

class CheckInStatusScreen extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final AppThemeData appColors;

  const CheckInStatusScreen({
    super.key,
    required this.tenantConfig,
    required this.appColors,
  });

  @override
  State<CheckInStatusScreen> createState() => _CheckInStatusScreenState();
}

class _CheckInStatusScreenState extends State<CheckInStatusScreen> {
  final TextEditingController _hotelIdController = TextEditingController();
  ScreenStatus _currentScreenStatus = ScreenStatus.input;
  String _statusMessage = '';

  final Map<String, dynamic> _loadedTenantConfig = {};
  late AppThemeData _loadedAppColors;

  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<Map<String, dynamic>> _adBanners = [];
  String _mainBannerPath = 'assets/images/banner/konekto_banner.png';

  final List<Map<String, dynamic>> _stayHistory = [
    {
      'hotelName': 'Copacabana Palace',
      'dates': '15 Mar - 20 Mar 2024',
      'image': 'assets/tenants/copacabana_palace/images/banners/banner1.png',
    },
    {
      'hotelName': 'Beach Park Resort',
      'dates': '10 Fev - 14 Fev 2023',
      'image': 'assets/tenants/beach_park/images/banners/banner2.png',
    },
    {
      'hotelName': 'Hotel Konekto City',
      'dates': '05 Jan - 07 Jan 2023',
      'image': 'assets/tenants/konekto_app/images/banners/banner1.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _statusMessage = "Por favor, insira o Código de Identificação do Hotel.";
    _loadedAppColors = widget.appColors;
    _loadKonektoTheme();
    _loadBanners();
  }

  Future<void> _loadKonektoTheme() async {
    try {
      final String themeJsonString =
          await rootBundle.loadString('assets/themes/konekto_app_theme.json');
      final Map<String, dynamic> themeConfig = json.decode(themeJsonString);
      if (mounted) {
        setState(() {
          _loadedAppColors = AppThemeData.fromJson(themeConfig);
        });
      }
    } catch (e) {
      print('Erro ao carregar o tema da Konekto: $e');
      if (mounted) {
        setState(() {
          _loadedAppColors = widget.appColors;
        });
      }
    }
  }

  Future<void> _loadBanners() async {
    try {
      final String themeJsonString =
          await rootBundle.loadString('assets/themes/konekto_app_theme.json');
      final Map<String, dynamic> themeConfig = json.decode(themeJsonString);
      setState(() {
        _mainBannerPath = themeConfig['mainBannerPath'] ?? 'assets/images/banner/konekto_banner.png';
      });
    } catch (e) {
      print('Erro ao carregar o banner principal: $e');
    }

    try {
      final String adJsonString = await rootBundle.loadString('assets/config/ad_banners.json');
      final List<dynamic> adList = json.decode(adJsonString);
      if (mounted) {
        setState(() {
          _adBanners = adList.cast<Map<String, dynamic>>();
        });
        _startAdCarousel();
      }
    } catch (e) {
      print('Erro ao carregar banners de anúncios: $e');
    }
  }

  void _startAdCarousel() {
    if (_adBanners.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 8), (Timer timer) {
        if (_pageController.hasClients) {
          int nextPage = (_currentPage + 1) % _adBanners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _hotelIdController.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadTenantConfig(String tenantIdentifier) async {
    try {
      final String hotelConfigPath = 'assets/tenants/$tenantIdentifier/hotel_default.json';
      final String hotelConfigString = await rootBundle.loadString(hotelConfigPath);
      final Map<String, dynamic> loadedTenantConfig = json.decode(hotelConfigString);

      final Map<String, dynamic> combinedConfig = {};
      combinedConfig.addAll(loadedTenantConfig);

      final String uiConfigJsonPath = loadedTenantConfig['uiConfigJsonPath'];
      final String uiConfigString = await rootBundle.loadString(uiConfigJsonPath);
      combinedConfig['uiConfig'] = json.decode(uiConfigString);

      final String themeConfigJsonPath = loadedTenantConfig['themeConfigJsonPath'];
      final String themeConfigString = await rootBundle.loadString(themeConfigJsonPath);
      combinedConfig['themeConfig'] = json.decode(themeConfigString);

      final String servicesListString =
          await rootBundle.loadString(loadedTenantConfig['servicesJsonPath']);
      combinedConfig['servicesList'] = json.decode(servicesListString);

      final String? preCheckInServicesJsonPath = loadedTenantConfig['preCheckInServicesJsonPath'];
      if (preCheckInServicesJsonPath != null && preCheckInServicesJsonPath.isNotEmpty) {
        final String preCheckInServicesString =
            await rootBundle.loadString(preCheckInServicesJsonPath);
        combinedConfig['preCheckInServicesList'] = json.decode(preCheckInServicesString);
      } else {
        combinedConfig['preCheckInServicesList'] = [];
      }

      final Map<String, dynamic>? roomServiceConfigFromHotel = loadedTenantConfig['roomServiceConfig'];
      if (roomServiceConfigFromHotel != null && roomServiceConfigFromHotel['jsonPath'] != null) {
        final String roomServiceConfigString =
            await rootBundle.loadString(roomServiceConfigFromHotel['jsonPath']);
        roomServiceConfigFromHotel['menu'] = json.decode(roomServiceConfigString);
        combinedConfig['roomServiceConfig'] = roomServiceConfigFromHotel;
      } else {
        combinedConfig['roomServiceConfig'] = {'menu': []};
      }

      final String spaConfigString = await rootBundle.loadString(loadedTenantConfig['spaJsonPath']);
      final Map<String, dynamic> spaConfigMap = json.decode(spaConfigString);
      combinedConfig['spaServicesList'] = spaConfigMap['spa_services'];

      final String restaurantsConfigString =
          await rootBundle.loadString(loadedTenantConfig['restaurantsJsonPath']);
      combinedConfig['restaurantsConfig'] = json.decode(restaurantsConfigString);

      final String notificationsConfigString =
          await rootBundle.loadString(loadedTenantConfig['notificationsJsonPath']);
      final Map<String, dynamic> notificationsConfigMap = json.decode(notificationsConfigString);
      combinedConfig['notificationsList'] = notificationsConfigMap['notifications'];

      if (loadedTenantConfig['checkInConfig'] == null) {
        throw Exception(
            'checkInConfig não encontrado no hotel_default.json do tenant $tenantIdentifier');
      }
      combinedConfig['checkInConfig'] = loadedTenantConfig['checkInConfig'];

      return combinedConfig;
    } catch (e) {
      throw Exception('Falha ao carregar configurações para o tenant "$tenantIdentifier": $e');
    }
  }

  Future<void> _processHotelIdAndCheckIn() async {
    final String hotelId = _hotelIdController.text.trim().toLowerCase();

    if (hotelId.isEmpty) {
      setState(() {
        _currentScreenStatus = ScreenStatus.error;
        _statusMessage = "Por favor, insira o Código de Identificação do Hotel.";
      });
      return;
    }

    if (_currentScreenStatus == ScreenStatus.loading) return;

    setState(() {
      _currentScreenStatus = ScreenStatus.loading;
      _statusMessage = 'Carregando informações do hotel...';
    });

    try {
      final Map<String, dynamic> fullConfig = await _loadTenantConfig(hotelId);
      final AppThemeData loadedAppColors = AppThemeData.fromJson(fullConfig['themeConfig']);

      String simulatedCheckInStatus;
      String simulatedStatusMessage;

      if (hotelId == 'beach_park') {
        simulatedCheckInStatus = 'success';
        simulatedStatusMessage = 'Check-in realizado com sucesso no Beach Park!';
      } else if (hotelId == 'copacabana_palace') {
        simulatedCheckInStatus = 'awaiting';
        simulatedStatusMessage =
            'Seu check-in no Copacabana Palace está aguardando aprovação. Por favor, entre em contato com a recepção.';
      } else if (hotelId == 'konekto_app') {
        simulatedCheckInStatus = 'success';
        simulatedStatusMessage = 'Check-in realizado com sucesso no Konekto Hotel!';
      } else {
        simulatedCheckInStatus = 'pending';
        simulatedStatusMessage =
            'Nenhum check-in encontrado para este código no ${fullConfig['name'] ?? 'Hotel'}. Verifique com a recepção.';
      }

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              tenantConfig: fullConfig,
              appColors: loadedAppColors,
              checkInStatus: simulatedCheckInStatus,
              statusMessage: simulatedStatusMessage,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erro ao carregar ou verificar check-in para o hotel "$hotelId": $e');
      setState(() {
        _currentScreenStatus = ScreenStatus.error;
        _statusMessage = 'Erro ao carregar dados ou verificar check-in para o hotel "$hotelId".';
      });
    } finally {
      if (mounted && _currentScreenStatus != ScreenStatus.loading) {
        setState(() {
          _currentScreenStatus = ScreenStatus.input;
        });
      }
    }
  }

  Future<void> _scanQrCode() async {
    if (_currentScreenStatus == ScreenStatus.loading) return;

    setState(() {
      _currentScreenStatus = ScreenStatus.loading;
      _statusMessage = 'Escaneando QR Code...';
    });

    try {
      await Future.delayed(const Duration(seconds: 3));

      final bool qrScanSuccess = Random().nextBool();
      if (qrScanSuccess) {
        final List<String> testTenantIds = ['beach_park', 'copacabana_palace', 'konekto_app'];
        final String scannedHotelId = testTenantIds[_random.nextInt(testTenantIds.length)];
        _hotelIdController.text = scannedHotelId;
        await _processHotelIdAndCheckIn();
      } else {
        setState(() {
          _currentScreenStatus = ScreenStatus.error;
          _statusMessage = 'Falha ao escanear o QR Code. Tente novamente.';
        });
      }
    } catch (e) {
      setState(() {
        _currentScreenStatus = ScreenStatus.error;
        _statusMessage = 'Ocorreu um erro ao escanear o QR Code: $e';
      });
    } finally {
      if (mounted && _currentScreenStatus != ScreenStatus.loading) {
        setState(() {
          _currentScreenStatus = ScreenStatus.input;
        });
      }
    }
  }

  final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 80.0),
            Text(
              'Konekto',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                  ),
            ),
            const SizedBox(height: 28.0),
            Text(
              'Sua jornada começa aqui',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 4.0),
            Card(
              color: _loadedAppColors.cardTransparent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildHotelIdentificationInputs(),
              ),
            ),
            if (_currentScreenStatus == ScreenStatus.loading ||
                _currentScreenStatus == ScreenStatus.error) ...{
              const SizedBox(height: 12.0),
              _buildStatusCard(),
            },
            const SizedBox(height: 12.0),
            Text(
              'Conheça nossas promoções',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24.0),
            _buildAdCarousel(),
            const SizedBox(height: 24.0),
            Text(
              'Sua história de estadias',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 0.0),
            _buildStayHistory(),
            const SizedBox(height: 2.0),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(appColors: _loadedAppColors),
    );
  }

  Widget _buildStatusCard() {
    final onAccentColor = Color(0xFFFFFFFF);
    final onErrorColor = Color(0xFFFFFFFF);

    return Card(
      color: _currentScreenStatus == ScreenStatus.loading
          ? _loadedAppColors.accent.withOpacity(0.9)
          : _loadedAppColors.error.withOpacity(0.9),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              _currentScreenStatus == ScreenStatus.loading
                  ? Icons.info_outline
                  : Icons.error_outline,
              color: _currentScreenStatus == ScreenStatus.loading ? onAccentColor : onErrorColor,
              size: 60,
            ),
            const SizedBox(height: 12.0),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _currentScreenStatus == ScreenStatus.loading ? onAccentColor : onErrorColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelIdentificationInputs() {
    final textColor = const Color(0xFF0F172A);
    final primaryText = textColor;
    final secondaryText = textColor.withOpacity(0.6);

    return Column(
      children: [
        Text(
          'Conecte-se ao seu hotel e descubra uma experiência personalizada',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColor.withOpacity(0.7),
                fontSize: 16,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 12.0),
        TextField(
          controller: _hotelIdController,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            labelText: 'Código de Acesso do Hotel',
            hintText: 'Ex: beach_park, copacabana_palace',
            labelStyle: TextStyle(color: secondaryText),
            hintStyle: TextStyle(color: secondaryText.withOpacity(0.7)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: _loadedAppColors.borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: _loadedAppColors.accent, width: 2.0),
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          ),
          style: TextStyle(color: primaryText, fontSize: 18.0),
          cursorColor: _loadedAppColors.accent,
        ),
        const SizedBox(height: 12.0),
        ElevatedButton(
          onPressed: _currentScreenStatus == ScreenStatus.loading
              ? null
              : () => _processHotelIdAndCheckIn(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _loadedAppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 8,
          ),
          child: _currentScreenStatus == ScreenStatus.loading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  'Confirmar Acesso',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
        ),
        const SizedBox(height: 12.0),
        Text(
          'ou',
          style: TextStyle(color: secondaryText, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12.0),
        OutlinedButton.icon(
          onPressed: _currentScreenStatus == ScreenStatus.loading ? null : _scanQrCode,
          icon: Icon(Icons.qr_code_scanner, color: _loadedAppColors.accent, size: 28),
          label: Text(
            'Escanear QR Code',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _loadedAppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            side: BorderSide(color: _loadedAppColors.accent, width: 2),
            elevation: 0,
            backgroundColor: Colors.transparent,
            splashFactory: InkRipple.splashFactory,
          ),
        ),
      ],
    );
  }

  Widget _buildFixedBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Image.asset(
        _mainBannerPath,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: _loadedAppColors.borderColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Center(
              child: Icon(Icons.image_not_supported, color: _loadedAppColors.secondaryText),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdCarousel() {
    if (_adBanners.isEmpty) {
      return const SizedBox.shrink();
    }
    final primaryText = const Color(0xFF0F172A);

    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: _loadedAppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _loadedAppColors.shadowColor.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _adBanners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final ad = _adBanners[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      ad['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _loadedAppColors.borderColor,
                          child: Center(
                            child: Icon(Icons.broken_image, color: primaryText),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        ad['title']!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_adBanners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 8.0,
              width: _currentPage == index ? 24.0 : 8.0,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? _loadedAppColors.accent
                    : _loadedAppColors.secondaryText.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4.0),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStayHistory() {
    if (_stayHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    final primaryText = const Color(0xFF0F172A);
    final secondaryText = const Color(0xFF0F172A).withOpacity(0.6);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stayHistory.length,
      itemBuilder: (context, index) {
        final stay = _stayHistory[index];
        return Card(
          color: _loadedAppColors.cardBackground,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    stay['image'] ?? 'assets/images/placeholder.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: _loadedAppColors.borderColor,
                        child: Icon(Icons.hotel, color: secondaryText, size: 24,),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stay['hotelName']!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stay['dates']!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: secondaryText),
              ],
            ),
          ),
        );
      },
    );
  }
}