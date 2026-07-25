import 'package:flutter/material.dart';
import 'package:konekto/templates/bosque/theme.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_screen.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_slide.dart';

/// Adaptado de `bosque_onboarding/code.html` ("Explore Sanctuary").
class BosqueOnboardingScreen extends StatelessWidget {
  final VoidCallback? onFinish;

  const BosqueOnboardingScreen({super.key, this.onFinish});

  @override
  Widget build(BuildContext context) {
    return GuestTemplateOnboardingScreen(
      theme: bosqueTheme,
      wordmark: 'Bosque',
      onFinish: onFinish,
      slides: const [
        GuestTemplateOnboardingSlide(title: 'Welcome to the forest.', subtitle: 'A natural escape, thoughtfully hosted.'),
        GuestTemplateOnboardingSlide(title: 'Explore Sanctuary.', subtitle: 'Find hidden trails and quiet corners made just for you.'),
        GuestTemplateOnboardingSlide(title: 'Whenever you need us.', subtitle: 'Room service and your guide, one tap away.'),
      ],
    );
  }
}
