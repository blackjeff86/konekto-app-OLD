// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'services_screen.dart';
import 'room_service_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'home_content_screen.dart';
import '../widgets/custom_header.dart';
import '../utils/app_theme_data.dart';
import 'events_screen.dart';
import 'restaurants_screen.dart';
import 'spa_screen.dart';
import 'tours_screen.dart';
import 'reservations_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final AppThemeData appColors;

  const HomeScreen({
    super.key,
    required this.tenantConfig,
    required this.appColors,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  late List<String> _bannerImages;
  int _currentImageIndex = 0;
  Timer? _timer;

  late final String _servicesBannerTitle;
  late final String _servicesBannerPath;

  final String _guestName = "Lucas";
  final String _guestEmail = "lucas.silva@email.com";
  final String _guestRoom = "305";

  bool _hasNewNotifications = true;

  @override
  void initState() {
    super.initState();

    _servicesBannerPath = widget.tenantConfig['bannerImages']['servicesBanner'] ?? '';
    _servicesBannerTitle = widget.tenantConfig['uiConfig']?['servicesScreen']?['title'] ?? 'Nossos Serviços';

    _loadBannerImages();
    _startImageTimer();
  }

  void _loadBannerImages() {
    final dynamic bannerImagesConfig = widget.tenantConfig['bannerImages']['homeBannerList'];
    if (bannerImagesConfig is List<dynamic> && bannerImagesConfig.isNotEmpty) {
      _bannerImages = List<String>.from(bannerImagesConfig);
    } else {
      final String? singleBannerPath = widget.tenantConfig['bannerImages']['homeBanner'];
      if (singleBannerPath != null) {
        _bannerImages = [singleBannerPath];
      } else {
        _bannerImages = [];
      }
    }
  }

  void _startImageTimer() {
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _bannerImages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToNotificationsScreen() {
    setState(() {
      _hasNewNotifications = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          appColors: widget.appColors,
          tenantConfig: widget.tenantConfig,
        ),
      ),
    );
  }

  void _handleGridButtonAction(String action) {
    final service = (widget.tenantConfig['servicesList'] as List<dynamic>?)?.firstWhere(
      (s) => s['action'] == action,
      orElse: () => null,
    );

    if (service == null && action != 'map' && action != 'history' && action != 'reservations' && action != 'restaurants' && action != 'spa' && action != 'events' && action != 'room_service' && action != 'tours') {
      print('Serviço não encontrado para a ação: $action');
      return;
    }

    switch (action) {
      case 'reservations':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReservationsScreen(
              tenantConfig: widget.tenantConfig,
              appColors: widget.appColors,
            ),
          ),
        );
        break;
      case 'room_service':
        final Map<String, dynamic> roomServiceConfig = widget.tenantConfig['roomServiceConfig'] ?? {};
        final List<dynamic> menuList = roomServiceConfig['menu'] ?? [];
        final List<Map<String, dynamic>> roomServiceMenu = menuList.map<Map<String, dynamic>>((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else {
            return {};
          }
        }).toList();

        if (roomServiceMenu.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomServiceScreen(
                serviceTitle: service!['title'] ?? 'Room Service',
                serviceDescription: roomServiceConfig['description'] ?? '',
                serviceImagePath: roomServiceConfig['bannerPath'] ?? '',
                menu: roomServiceMenu,
                appColors: widget.appColors,
              ),
            ),
          );
        }
        break;
      case 'restaurants':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantsScreen(
              tenantConfig: widget.tenantConfig,
              appColors: widget.appColors,
            ),
          ),
        );
        break;
      case 'spa':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpaScreen(
              tenantConfig: widget.tenantConfig,
              appColors: widget.appColors,
            ),
          ),
        );
        break;
      case 'events':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventsScreen(
              tenantConfig: widget.tenantConfig,
              appColors: widget.appColors,
            ),
          ),
        );
        break;
      case 'tours':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToursScreen(
              tenantConfig: widget.tenantConfig,
              appColors: widget.appColors,
            ),
          ),
        );
        break;
      case 'map':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              tenantConfig: widget.tenantConfig,
              appColors: widget.appColors,
            ),
          ),
        );
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryScreen(appColors: widget.appColors),
          ),
        );
        break;
      default:
        print('Ação não reconhecida: $action');
    }
  }

  void _onBottomBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeContentScreen(
          tenantConfig: widget.tenantConfig,
          appColors: widget.appColors,
          onGridButtonTap: _handleGridButtonAction,
          guestName: _guestName,
          guestEmail: _guestEmail,
          guestRoom: _guestRoom,
        );
      case 1:
        return ServicesScreen(
          tenantConfig: widget.tenantConfig,
          appColors: widget.appColors,
          bannerTitle: _servicesBannerTitle,
          bannerImagePath: _servicesBannerPath,
        );
      case 2:
        return ReservationsScreen(
          tenantConfig: widget.tenantConfig,
          appColors: widget.appColors,
        );
      case 3:
        return ProfileScreen(appColors: widget.appColors);
      default:
        return Center(
          child: Text('Tela não encontrada!', style: TextStyle(color: widget.appColors.primaryText)),
        );
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home_outlined':
        return Icons.home_outlined;
      case 'room_service_outlined':
        return Icons.room_service_outlined;
      case 'calendar_today_outlined':
        return Icons.calendar_today_outlined;
      case 'person_outlined':
        return Icons.person_outlined;
      default:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> bottomBarItems = widget.tenantConfig['uiConfig']['homeScreen']['bottomBarItems'];

    return Scaffold(
      backgroundColor: widget.appColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: CustomHeader(
          title: widget.tenantConfig['name'] ?? 'Konekto App',
          leading: const SizedBox.shrink(),
          trailing: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _hasNewNotifications ? Icons.notifications : Icons.notifications_outlined,
                  color: _hasNewNotifications ? widget.appColors.primaryText : widget.appColors.secondaryText,
                  size: 28,
                ),
                onPressed: _navigateToNotificationsScreen,
              ),
              if (_hasNewNotifications)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          appColors: widget.appColors,
          titleFontSize: (widget.tenantConfig['uiConfig']?['homeScreen']?['headerTitleFontSize'] ?? 24.0) as double,
          headerTitleType: widget.tenantConfig['headerTitleType'] ?? 'text',
          logoPath: widget.tenantConfig['logoPath'] ?? '',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Center(
          child: _buildCurrentBody(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(bottomBarItems),
    );
  }

  Widget _buildBottomNavigationBar(List<dynamic> bottomBarItems) {
    return BottomNavigationBar(
      backgroundColor: widget.appColors.background,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: widget.appColors.accent, 
      unselectedItemColor: widget.appColors.secondaryText,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: bottomBarItems.map((item) => BottomNavigationBarItem(
        icon: Icon(_getIconData(item['icon'])),
        label: item['label'],
      )).toList(),
      currentIndex: _selectedIndex,
      onTap: _onBottomBarItemTapped,
    );
  }
}