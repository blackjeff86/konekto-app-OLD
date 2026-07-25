import 'package:flutter/material.dart';
import 'package:konekto/templates/aura/theme.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_screen.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_slide.dart';

/// Adaptado de `aura_onboarding/code.html` (só 1 slide exportado — os
/// outros 2 seguem o mesmo tom de voz).
class AuraOnboardingScreen extends StatelessWidget {
  final VoidCallback? onFinish;

  const AuraOnboardingScreen({super.key, this.onFinish});

  @override
  Widget build(BuildContext context) {
    return GuestTemplateOnboardingScreen(
      theme: auraTheme,
      wordmark: 'AURA',
      onFinish: onFinish,
      slides: const [
        GuestTemplateOnboardingSlide(title: 'Welcome to your sanctuary.', subtitle: 'Everything you need, at your fingertips.'),
        GuestTemplateOnboardingSlide(title: 'Your room, your rules.', subtitle: 'Wi-Fi, room details, and requests — all in one place.'),
        GuestTemplateOnboardingSlide(title: 'Always within reach.', subtitle: 'Message the concierge anytime, day or night.'),
      ],
    );
  }
}
