import 'package:flutter/material.dart';
import 'package:konekto/templates/pulse/theme.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_screen.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_slide.dart';

/// Adaptado de `pulse_onboarding/code.html` ("Future of Hospitality.").
class PulseOnboardingScreen extends StatelessWidget {
  final VoidCallback? onFinish;

  const PulseOnboardingScreen({super.key, this.onFinish});

  @override
  Widget build(BuildContext context) {
    return GuestTemplateOnboardingScreen(
      theme: pulseTheme,
      wordmark: 'PULSE',
      onFinish: onFinish,
      slides: const [
        GuestTemplateOnboardingSlide(title: 'The future of hospitality.', subtitle: 'Every service, one tap away.'),
        GuestTemplateOnboardingSlide(title: 'AI Concierge, always on.', subtitle: 'Ask anything, anytime — Pulse never sleeps.'),
        GuestTemplateOnboardingSlide(title: 'Your stay, digitized.', subtitle: 'Digital key, wallet, and room control in your pocket.'),
      ],
    );
  }
}
