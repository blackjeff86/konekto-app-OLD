import 'package:flutter/material.dart';
import 'package:konekto/templates/horizon/theme.dart';
import 'package:konekto/templates/shared/guest_template_splash_screen.dart';

/// Adaptado de `horizon_splash_screen/code.html`.
class HorizonSplashScreen extends StatelessWidget {
  const HorizonSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestTemplateSplashScreen(
      theme: horizonTheme,
      wordmark: 'Horizon',
      tagline: 'Resorts & Spas',
      footnote: 'Curating your escape',
    );
  }
}
