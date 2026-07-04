import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual das telas de marca Konekto (login, acesso ao hotel,
/// status de check-in) — independente do tema por tenant, que já é
/// resolvido via JSON em [lib/app/tenants].
class KonektoBrand {
  KonektoBrand._();

  static const Color ink = Color(0xFF14181F);
  static const Color inkSoft = Color(0xFF262C38);
  static const Color gold = Color(0xFFB8935F);
  static const Color goldLight = Color(0xFFD9C6A5);
  static const Color cream = Color(0xFFFAF7F2);
  static const Color sand = Color(0xFFF1EAE0);
  static const Color slate = Color(0xFF5B6472);

  static TextStyle display({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w600,
    Color color = ink,
    double? height,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle eyebrow({Color color = gold, double fontSize = 12}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 2.2,
    );
  }

  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color color = slate,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

/// Botão pílula com o acabamento de marca (usado nas telas de login/acesso).
class KonektoPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;

  const KonektoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: KonektoBrand.ink,
          disabledBackgroundColor: KonektoBrand.ink.withValues(alpha: 0.6),
          foregroundColor: KonektoBrand.cream,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: KonektoBrand.gold),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 18, color: KonektoBrand.gold),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Campo de texto com o acabamento de marca: borda sutil, ícone de contexto,
/// destaque dourado no foco — em vez do preenchimento cinza chapado padrão.
class KonektoTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextAlign textAlign;

  const KonektoTextField({
    super.key,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: textAlign,
      style: KonektoBrand.body(fontSize: 15, color: KonektoBrand.ink, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: KonektoBrand.body(fontSize: 14, color: KonektoBrand.slate),
        prefixIcon: Icon(icon, size: 20, color: KonektoBrand.gold),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: KonektoBrand.sand, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KonektoBrand.gold, width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Painel superior escuro com o brasão da Konekto — usado como cabeçalho
/// decorativo nas telas de marca, criando profundidade em relação ao
/// conteúdo claro abaixo.
class KonektoHeroPanel extends StatelessWidget {
  final double height;
  final String? eyebrowText;

  const KonektoHeroPanel({super.key, this.height = 240, this.eyebrowText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      // Cor sólida (mesma do botão primário) e sem cantos arredondados aqui:
      // a curva da transição fica só no cartão claro que sobrepõe por cima,
      // evitando duas curvas com raios diferentes se sobrepondo.
      color: KonektoBrand.ink,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 44),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (eyebrowText != null) ...[
              Text(eyebrowText!, style: KonektoBrand.eyebrow()),
              const SizedBox(height: 14),
            ],
            Container(
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KonektoBrand.gold, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const ClipOval(
                child: Image(
                  image: AssetImage('assets/app_assets/images/konekto_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
