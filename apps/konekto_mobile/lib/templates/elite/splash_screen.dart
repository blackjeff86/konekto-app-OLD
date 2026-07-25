import 'package:flutter/material.dart';
import 'package:konekto/templates/elite/theme.dart';
import 'package:konekto/templates/shared/guest_template_splash_screen.dart';

/// Adaptado de `lite_splash_screen/code.html`.
class EliteSplashScreen extends StatelessWidget {
  const EliteSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestTemplateSplashScreen(
      theme: eliteTheme,
      wordmark: 'Élite',
      tagline: 'The Art of Grand Living',
      footnote: 'Est. 1924',
    );
  }
}
