import 'package:flutter/material.dart';
import 'package:konekto/templates/pulse/theme.dart';
import 'package:konekto/templates/shared/guest_template_splash_screen.dart';

/// Adaptado de `pulse_splash_screen/code.html`.
class PulseSplashScreen extends StatelessWidget {
  const PulseSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestTemplateSplashScreen(
      theme: pulseTheme,
      wordmark: 'PULSE',
      tagline: 'Authenticating',
      footnote: 'Secure Node',
    );
  }
}
