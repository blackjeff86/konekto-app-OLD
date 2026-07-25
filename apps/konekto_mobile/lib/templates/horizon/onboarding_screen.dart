import 'package:flutter/material.dart';
import 'package:konekto/templates/horizon/theme.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_screen.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_slide.dart';

/// Adaptado de `horizon_onboarding/code.html` ("Your Escape Awaits" — só 1
/// slide exportado, os outros 2 seguem o mesmo tom de voz).
class HorizonOnboardingScreen extends StatelessWidget {
  final VoidCallback? onFinish;

  const HorizonOnboardingScreen({super.key, this.onFinish});

  @override
  Widget build(BuildContext context) {
    return GuestTemplateOnboardingScreen(
      theme: horizonTheme,
      wordmark: 'HORIZON',
      onFinish: onFinish,
      slides: const [
        GuestTemplateOnboardingSlide(
          title: 'Your escape awaits.',
          subtitle: "Experience the world's most exclusive resorts at your fingertips.",
        ),
        GuestTemplateOnboardingSlide(title: 'Your villa, curated.', subtitle: 'Room details, wifi, and requests — all in one place.'),
        GuestTemplateOnboardingSlide(title: 'Every experience, one tap away.', subtitle: 'Dining, excursions, and the concierge, always within reach.'),
      ],
    );
  }
}
