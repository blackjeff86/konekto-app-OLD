import 'package:flutter/material.dart';
import 'package:konekto/templates/aura/theme.dart';
import 'package:konekto/templates/shared/guest_template_splash_screen.dart';

/// Adaptado de `aura_splash_screen/code.html`.
class AuraSplashScreen extends StatelessWidget {
  const AuraSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestTemplateSplashScreen(
      theme: auraTheme,
      wordmark: 'AURA',
      tagline: 'Essential Hospitality',
      footnote: 'The Elite Collection',
    );
  }
}
