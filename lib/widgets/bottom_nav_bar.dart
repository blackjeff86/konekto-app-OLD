// lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart'; // Importa AppThemeData

class BottomNavBar extends StatefulWidget {
  final AppThemeData appColors; // Recebe as cores do tema Konekto

  const BottomNavBar({
    super.key,
    required this.appColors,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0; // Estado para o item selecionado na barra

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
          // Em uma aplicação real, aqui você faria a navegação para a tela correspondente.
          // Por exemplo:
          // if (index == 0) {
          //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(tenantConfig: {}, appColors: widget.appColors)));
          // } else if (index == 1) {
          //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ServicesScreen(tenantConfig: {}, appColors: widget.appColors)));
          // }
          // ... e assim por diante para as outras telas.
        });
      },
      selectedItemColor: widget.appColors.secondaryText,   // Cor para o item selecionado (cinza)
      unselectedItemColor: widget.appColors.secondaryText, // Cor para os itens não selecionados (cinza)
      backgroundColor: widget.appColors.background,        // Fundo da barra (cinza muito claro Konekto)
      type: BottomNavigationBarType.fixed, // Garante que todos os itens são visíveis
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apps),
          label: 'Serviços',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Reservas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
