// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import 'check_in_status_screen.dart';

class User {
  final String name;
  final String role;
  final String id;
  final String profileImagePath;

  User({
    required this.name,
    required this.role,
    required this.id,
    required this.profileImagePath,
  });
}

class ProfileScreen extends StatefulWidget {
  final AppThemeData appColors;

  const ProfileScreen({
    super.key,
    required this.appColors,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User _currentUser = User(
    name: 'Lucas',
    role: 'Hóspede',
    id: '123456',
    profileImagePath:
        'assets/tenants/konekto_app_default/images/profile/lucas_profile.jpg',
  );

  void _onTapProfilePhoto() {
    print(
        'Tocou na foto de perfil. Lógica para alterar a foto seria implementada aqui.');
  }

  void _logout() {
    print('Realizando logout do usuário...');

    final AppThemeData konektoDefaultColors = AppThemeData(
      primary: Colors.white,
      onPrimary: const Color(0xFF0F172A),
      accent: const Color(0xFF3B82F6),
      primaryText: const Color(0xFF111416),
      secondaryText: const Color(0xFF637287),
      background: Colors.grey[50]!,
      cardBackground: Colors.white,
      buttonBackground: const Color(0xFF0F172A),
      buttonText: Colors.white,
      borderColor: const Color(0xFFE5E8EA),
      success: Colors.green,
      warning: Colors.orange,
      error: Colors.red,
      onError: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      splashScreenIconPath: 'assets/images/icons/default_icon.png',
      // Novos campos transparentVariants
      cardTransparent: Colors.transparent,
      cardWhite70: const Color(0xB3FFFFFF),
      cardBlack50: const Color(0x80000000),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInStatusScreen(
          tenantConfig: const {},
          appColors: konektoDefaultColors,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 16),
          _buildProfileOptions(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: widget.appColors.background,
      child: Column(
        children: [
          GestureDetector(
            onTap: _onTapProfilePhoto,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(64),
              child: Image.asset(
                _currentUser.profileImagePath,
                width: 128,
                height: 128,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 128,
                    height: 128,
                    color: widget.appColors.borderColor,
                    child: Icon(Icons.person,
                        color: widget.appColors.secondaryText, size: 60),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser.name,
            style: TextStyle(
              color: widget.appColors.primaryText,
              fontSize: 22,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser.role,
            style: TextStyle(
              color: widget.appColors.secondaryText,
              fontSize: 16,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'ID: ${_currentUser.id}',
            style: TextStyle(
              color: widget.appColors.secondaryText,
              fontSize: 16,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Column(
      children: [
        _buildSectionTitle('Dados'),
        _buildProfileOption(
          title: 'Ver/Editar dados',
          icon: Icons.person_outline,
          onTap: () {
            print('Navegar para a tela de edição de dados');
          },
        ),
        _buildSectionTitle('Histórico'),
        _buildProfileOption(
          title: 'Compras',
          icon: Icons.shopping_bag_outlined,
          onTap: () {
            print('Navegar para a tela de histórico de compras');
          },
        ),
        _buildProfileOption(
          title: 'Reservas',
          icon: Icons.book_online_outlined,
          onTap: () {
            print('Navegar para a tela de histórico de reservas');
          },
        ),
        _buildSectionTitle('Conta'),
        _buildProfileOption(
          title: 'Configurações',
          icon: Icons.settings_outlined,
          onTap: () {
            print('Navegar para a tela de configurações');
          },
        ),
        _buildProfileOption(
          title: 'Sair',
          icon: Icons.logout,
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      color: widget.appColors.background,
      child: Text(
        title,
        style: TextStyle(
          color: widget.appColors.primaryText,
          fontSize: 18,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: widget.appColors.background,
          border: Border(
            bottom: BorderSide(
              width: 1,
              color: widget.appColors.borderColor,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: widget.appColors.primaryText),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: widget.appColors.primaryText,
                  fontSize: 16,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: widget.appColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
