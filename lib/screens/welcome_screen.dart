// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import 'home_screen.dart'; // Para navegar para a tela principal
import '../utils/app_theme_data.dart'; // Para as cores do tema
// Importe as telas de serviço para navegação
import 'restaurants_screen.dart';
import 'spa_screen.dart';
import 'events_screen.dart';
import 'tours_screen.dart';
import 'check_in_status_screen.dart'; // Para o botão "Voltar para Check-in"

class WelcomeScreen extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final AppThemeData appColors; // appColors AQUI É SEMPRE O TEMA PADRÃO DA KONEKTO
  final String checkInStatus; // O status do check-in do hóspede (success/awaiting)
  final String statusMessage; // A mensagem de status a ser exibida

  const WelcomeScreen({
    super.key,
    required this.tenantConfig,
    required this.appColors, // Cores padrão da Konekto
    required this.checkInStatus,
    required this.statusMessage,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Variável para armazenar o tema ESPECÍFICO do hotel (tenant)
  // Esta variável será usada SOMENTE ao passar o tema para a HomeScreen
  // e para as telas de serviço do hotel. Nenhum elemento visual desta
  // tela (WelcomeScreen) deve usar _hotelThemeForHomeScreen diretamente.
  late AppThemeData _hotelThemeForHomeScreen;

  @override
  void initState() {
    super.initState();
    // Inicializa _hotelThemeForHomeScreen com base no themeConfig do tenant
    // para ser passado para a HomeScreen.
    _hotelThemeForHomeScreen = AppThemeData.fromJson(widget.tenantConfig['themeConfig']);

    // Se o check-in for bem-sucedido, navega automaticamente para a HomeScreen
    if (widget.checkInStatus == 'success') {
      Future.delayed(const Duration(seconds: 3), () { // Pequeno atraso para o hóspede ler
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                tenantConfig: widget.tenantConfig,
                appColors: _hotelThemeForHomeScreen, // Passa as cores DO TEMA DO HOTEL para a HomeScreen
              ),
            ),
          );
        }
      });
    }
  }

  void _navigateToService(String serviceAction) {
    // Para navegação de serviços (Restaurantes, Spa, etc.), passamos as cores DO HOTEL,
    // pois estas telas pertencem ao contexto do hotel.
    final List<dynamic> services = widget.tenantConfig['servicesList'] ?? [];
    final Map<String, dynamic>? serviceConfig = services.firstWhere(
      (s) => s['action'] == serviceAction,
      orElse: () => null,
    );

    if (serviceConfig == null) {
      print('Serviço "$serviceAction" não encontrado na configuração do hotel.');
      return;
    }

    Widget screenToNavigate;
    switch (serviceAction) {
      case 'restaurants':
        screenToNavigate = RestaurantsScreen(tenantConfig: widget.tenantConfig, appColors: _hotelThemeForHomeScreen);
        break;
      case 'spa':
        screenToNavigate = SpaScreen(tenantConfig: widget.tenantConfig, appColors: _hotelThemeForHomeScreen);
        break;
      case 'events':
        screenToNavigate = EventsScreen(tenantConfig: widget.tenantConfig, appColors: _hotelThemeForHomeScreen);
        break;
      case 'tours':
        screenToNavigate = ToursScreen(tenantConfig: widget.tenantConfig, appColors: _hotelThemeForHomeScreen);
        break;
      default:
        print('Ação de serviço desconhecida para navegação: $serviceAction');
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screenToNavigate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String hotelLogoPath = widget.tenantConfig['logoPath'] ?? 'assets/images/placeholder.png';
    final String hotelName = widget.tenantConfig['name'] ?? 'Seu Hotel';

    Color statusCardColor;
    Color statusIconTextColor;
    IconData statusIcon;

    // Cores do Card de Status SEMPRE usam as cores PADRÃO da KONEKTO
    switch (widget.checkInStatus) {
      case 'success':
        statusCardColor = widget.appColors.success;
        statusIconTextColor = widget.appColors.onError; // Texto/ícone branco para contraste
        statusIcon = Icons.check_circle_outline;
        break;
      case 'awaiting':
        statusCardColor = widget.appColors.warning;
        statusIconTextColor = widget.appColors.onError;
        statusIcon = Icons.access_time;
        break;
      default: // Para 'pending' ou qualquer outro status inesperado
        statusCardColor = widget.appColors.error;
        statusIconTextColor = widget.appColors.onError;
        statusIcon = Icons.info_outline;
        break;
    }

    return Scaffold(
      backgroundColor: widget.appColors.primary, // Fundo com a cor primária da KONEKTO (branco)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60.0),
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.appColors.cardBackground, // Fundo do círculo da logo da KONEKTO (branco)
                  boxShadow: [
                    BoxShadow(
                      color: widget.appColors.shadowColor, // Sombra da KONEKTO
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    hotelLogoPath, // LOGO DO HOTEL (vem do tenantConfig)
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.hotel, size: 100, color: widget.appColors.secondaryText); // Ícone KONEKTO secundário
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            Text(
              'Bem-vindo ao $hotelName!', // NOME DO HOTEL (vem do tenantConfig)
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: widget.appColors.primaryText, // Texto sempre com a cor primária da KONEKTO
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24.0),
            // Card de Status do Check-in
            Card(
              color: statusCardColor, // Cor de status da KONEKTO
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      statusIcon,
                      color: statusIconTextColor, // Cor de texto/ícone da KONEKTO
                      size: 60,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      widget.statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: statusIconTextColor, // Cor de texto da KONEKTO
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            // Botões "Voltar para Check-in" e "Confirmar Acesso"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Volta para a tela de check-in
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckInStatusScreen(
                              tenantConfig: const {}, // Passa um tenantConfig VAZIO para CheckInStatusScreen
                              appColors: widget.appColors, // Passa as cores PADRÃO DA KONEKTO de volta
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: widget.appColors.borderColor, width: 1), // Borda da KONEKTO
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Voltar para Check-in',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: widget.appColors.primaryText, // Texto da KONEKTO
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Espaçamento entre os botões
                  // Este botão só aparece se o check-in não for 'success' (auto-navegação)
                  if (widget.checkInStatus != 'success')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navega para a tela principal do hotel
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                tenantConfig: widget.tenantConfig,
                                appColors: _hotelThemeForHomeScreen, // Passa as cores DO TEMA DO HOTEL
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.appColors.buttonBackground, // Fundo do botão SEMPRE da KONEKTO
                          foregroundColor: widget.appColors.buttonText, // Texto do botão SEMPRE da KONEKTO
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Confirmar Acesso',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: widget.appColors.buttonText, // Texto do botão SEMPRE da KONEKTO
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Mostra os serviços SOMENTE se o status for 'awaiting'
            if (widget.checkInStatus == 'awaiting')
              _buildPreCheckInServices(),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }

  Widget _buildPreCheckInServices() {
    // MODIFICADO: Agora usa a lista de serviços de pré-check-in do tenantConfig
    final List<dynamic> preCheckInServicesList = widget.tenantConfig['preCheckInServicesList'] ?? [];

    final List<Map<String, dynamic>> servicesWithBanners = preCheckInServicesList
        .where((service) => service['bannerPath'] != null && service['bannerPath'].isNotEmpty)
        .map<Map<String, dynamic>>((service) => Map<String, dynamic>.from(service))
        .toList();


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: widget.appColors.borderColor, height: 40), // Divisor SEMPRE da KONEKTO
        Text(
          'Enquanto aguarda, explore os serviços do ${widget.tenantConfig['name'] ?? 'Hotel'}!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: widget.appColors.primaryText, // Texto SEMPRE da KONEKTO
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16.0),
        Column(
          children: servicesWithBanners.map((service) {
            return _buildServiceListItem(
              context,
              service['title']!,
              service['bannerPath']!,
              // Passa as cores do HOTEL para as telas de serviço
              () => _navigateToService(service['action']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceListItem(BuildContext context, String title, String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: widget.appColors.cardBackground, // Fundo do card SEMPRE da KONEKTO
        elevation: 3, 
        margin: const EdgeInsets.only(bottom: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath, // Imagem do serviço (vem do tenantConfig)
                  width: 90, 
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 70,
                      color: widget.appColors.borderColor, // Borda SEMPRE da KONEKTO
                      child: Center(
                        child: Icon(Icons.broken_image, color: widget.appColors.secondaryText), // Ícone SEMPRE da KONEKTO
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: widget.appColors.primaryText, // Texto SEMPRE da KONEKTO
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 20, color: widget.appColors.secondaryText), // Ícone SEMPRE da KONEKTO
            ],
          ),
        ),
      ),
    );
  }
}
