import 'package:flutter/material.dart';
import 'package:konekto/theme/konekto_brand.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: KonektoBrand.ink),
            child: const Center(child: KonektoMark(size: 56)),
          ),
          const SizedBox(height: 16),
          // Nome do Perfil
          const Text(
            'Jeff Brito',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111416),
              fontSize: 22,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              height: 1.27,
            ),
          ),
          const SizedBox(height: 4),
          // Subtítulo
          const Text(
            'Hóspede',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF637287),
              fontSize: 16,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
          const SizedBox(height: 4),
          // ID do Usuário
          const Text(
            'ID: 123456',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF637287),
              fontSize: 16,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
          const SizedBox(height: 32),
          // Seções do Perfil
          _buildProfileSection(
            'Dados',
            'Ver/Editar dados',
            Icons.person_outline,
            context,
          ),
          _buildProfileSection(
            'Histórico',
            'Compras',
            Icons.shopping_cart_outlined,
            context,
          ),
          _buildProfileSection(
            '',
            'Reservas',
            Icons.bookmark_border,
            context,
          ),
          _buildProfileSection(
            'Conta',
            'Configurações',
            Icons.settings_outlined,
            context,
          ),
          _buildProfileSection(
            '',
            'Sair',
            Icons.logout,
            context,
            isLogout: true,
          ),
        ],
      ),
    );
  }

  // Widget para criar as seções (Dados, Histórico, Conta)
  Widget _buildProfileSection(
    String title,
    String subtitle,
    IconData? icon,
    BuildContext context, {
    bool isLogout = false,
  }) {
    return Column(
      children: [
        if (title.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111416),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Container(
          color: const Color(0xFFf2f2f2),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(
              icon,
              color: isLogout ? Colors.red : const Color(0xFF637287),
            ),
            title: Text(
              subtitle,
              style: TextStyle(
                color: isLogout ? Colors.red : const Color(0xFF111416),
                fontSize: 16,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
            trailing: !isLogout
                ? const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF637287),
                    size: 16,
                  )
                : null,
            onTap: () {
              // Ação ao tocar no item (navegar para outra tela, por exemplo)
              if (isLogout) {
                // Lógica de logout
                print('Usuário deslogado.');
              } else {
                print('Item "$subtitle" clicado.');
              }
            },
          ),
        ),
        const SizedBox(height: 1), // Espaço entre os itens
      ],
    );
  }
}