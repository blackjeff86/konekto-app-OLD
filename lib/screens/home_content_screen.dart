// lib/screens/home_content_screen.dart

import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import '../widgets/image_banner.dart';

class HomeContentScreen extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final AppThemeData appColors;
  final Function(String) onGridButtonTap;
  final String guestName;
  final String guestEmail;
  final String guestRoom;

  const HomeContentScreen({
    super.key,
    required this.tenantConfig,
    required this.appColors,
    required this.onGridButtonTap,
    required this.guestName,
    required this.guestEmail,
    required this.guestRoom,
  });
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'map':
        return Icons.map;
      case 'history':
        return Icons.history;
      case 'directions_car':
        return Icons.directions_car;
      case 'pool':
        return Icons.pool;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'spa':
        return Icons.spa;
      case 'room_service':
        return Icons.room_service;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'event':
        return Icons.event;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'support_agent':
        return Icons.support_agent;
      case 'wifi':
        return Icons.wifi;
      case 'local_parking':
        return Icons.local_parking;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'phone_in_talk':
        return Icons.phone_in_talk;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'info':
        return Icons.info;
      case 'celebration':
        return Icons.celebration;
      case 'flight':
        return Icons.flight;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'child_friendly':
        return Icons.child_friendly;
      default:
        return Icons.error;
    }
  }

  Widget _buildNavigationButton(
      BuildContext context, String title, IconData icon,
      {required double width, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: appColors.shadowColor,
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: appColors.primaryText, // CORREÇÃO: Usa a cor de texto principal para o ícone
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: appColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGrid(BuildContext context) {
    final List<dynamic> gridButtonsConfig = tenantConfig['uiConfig']['homeScreen']['gridButtons'];
    const int buttonsPerRow = 2;
    const double spacing = 12.0;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonWidth = (screenWidth - (2 * 16.0) - ((buttonsPerRow - 1) * spacing)) / buttonsPerRow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: WrapAlignment.start,
        children: gridButtonsConfig.map((buttonData) {
          return _buildNavigationButton(
            context,
            buttonData['title'],
            _getIconData(buttonData['icon']),
            width: buttonWidth,
            onTap: () => onGridButtonTap(buttonData['action']),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWelcomeInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo, $guestName!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: appColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check-in realizado com sucesso! Seu quarto é o $guestRoom.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: appColors.primaryText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados de acesso',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: appColors.primaryText,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Wi-fi', 'Beach Park Wi-fi'),
          const SizedBox(height: 12),
          _buildInfoRow(context, 'Login', guestEmail),
          const SizedBox(height: 12),
          _buildInfoRow(context, 'Senha', '123456'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: appColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          '|',
          style: TextStyle(
            color: appColors.secondaryText,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: appColors.primaryText,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> bannerImages = List<String>.from(tenantConfig['bannerImages']['homeBannerList']);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageBanner(
            imagePath: bannerImages[0],
            height: 250,
            appColors: appColors,
          ),
          _buildWelcomeInfo(context),
          _buildAccessInfo(context),
          _buildNavigationGrid(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}