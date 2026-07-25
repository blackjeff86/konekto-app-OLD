import 'package:flutter/material.dart';
import 'package:konekto/templates/bosque/theme.dart';
import 'package:konekto/templates/shared/guest_template_splash_screen.dart';

/// Adaptado de `bosque_splash_screen/code.html`.
class BosqueSplashScreen extends StatelessWidget {
  const BosqueSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestTemplateSplashScreen(
      theme: bosqueTheme,
      wordmark: 'Bosque',
      tagline: 'Natural Hospitality',
      footnote: 'Rooted in nature',
    );
  }
}
