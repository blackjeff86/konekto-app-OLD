import 'package:flutter/material.dart';
import 'package:konekto/templates/elite/theme.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_screen.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_slide.dart';

/// Adaptado de `lite_onboarding/code.html` — os 3 slides já vêm completos
/// no mockup (eyebrow + título + subtítulo cada), diferente dos outros 3
/// templates que só exportaram 1 slide de exemplo.
class EliteOnboardingScreen extends StatelessWidget {
  final VoidCallback? onFinish;

  const EliteOnboardingScreen({super.key, this.onFinish});

  @override
  Widget build(BuildContext context) {
    return GuestTemplateOnboardingScreen(
      theme: eliteTheme,
      wordmark: 'ÉLITE',
      onFinish: onFinish,
      slides: const [
        GuestTemplateOnboardingSlide(
          eyebrow: 'Moments of Arrival',
          title: 'Seamless Check-in',
          subtitle: 'Your transition from travel to tranquility is immediate and invisible.',
        ),
        GuestTemplateOnboardingSlide(
          eyebrow: 'Always at Hand',
          title: 'Private Concierge',
          subtitle: 'A dedicated attendant anticipating every desire before it is spoken.',
        ),
        GuestTemplateOnboardingSlide(
          eyebrow: 'The Uncommon Path',
          title: 'Curated Experiences',
          subtitle: 'Access the inaccessible with itineraries designed solely for you.',
        ),
      ],
    );
  }
}
