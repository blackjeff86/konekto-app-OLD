import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/guest_template_onboarding_slide.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

/// Carrossel de onboarding (PageView + indicadores + Pular/Avançar) —
/// reaproveitado pelos 4 templates novos, só texto/paleta muda. Os mockups
/// do Stitch usam foto de fundo full-bleed por slide; aqui, como no Splash,
/// usamos um fundo em gradiente da própria paleta em vez de foto de
/// estoque genérica. Ainda não ligado a nenhum fluxo real — Fase 4 decide
/// se/como isso entra (o app hoje vai direto do código de acesso pra Home).
class GuestTemplateOnboardingScreen extends StatefulWidget {
  final GuestTemplateTheme theme;
  final String wordmark;
  final List<GuestTemplateOnboardingSlide> slides;
  final VoidCallback? onFinish;

  const GuestTemplateOnboardingScreen({
    super.key,
    required this.theme,
    required this.wordmark,
    required this.slides,
    this.onFinish,
  });

  @override
  State<GuestTemplateOnboardingScreen> createState() => _GuestTemplateOnboardingScreenState();
}

class _GuestTemplateOnboardingScreenState extends State<GuestTemplateOnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < widget.slides.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      widget.onFinish?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final colors = theme.colors;
    final isLast = _page == widget.slides.length - 1;
    return ColoredBox(
      color: colors.primary,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.wordmark,
                    style: theme.display(fontSize: 20, fontWeight: FontWeight.w600, color: colors.onPrimary).copyWith(letterSpacing: 2),
                  ),
                  GestureDetector(
                    onTap: widget.onFinish,
                    child: Text(
                      'SKIP',
                      style: theme.body(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onPrimary.withValues(alpha: 0.8)).copyWith(letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final slide = widget.slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (slide.eyebrow != null) ...[
                          Text(
                            slide.eyebrow!.toUpperCase(),
                            style: theme.body(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onPrimary.withValues(alpha: 0.7)).copyWith(letterSpacing: 2),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(slide.title, style: theme.display(fontSize: 32, fontWeight: FontWeight.w400, color: colors.onPrimary)),
                        const SizedBox(height: 12),
                        Text(slide.subtitle, style: theme.body(fontSize: 16, color: colors.onPrimary.withValues(alpha: 0.85), height: 1.4)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.onPrimary,
                        foregroundColor: colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.radiusLg)),
                      ),
                      child: Text(isLast ? 'Get Started' : 'Next', style: theme.body(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.slides.length, (index) {
                      final active = index == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 6,
                        height: 4,
                        decoration: BoxDecoration(
                          color: active ? colors.onPrimary : colors.onPrimary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
