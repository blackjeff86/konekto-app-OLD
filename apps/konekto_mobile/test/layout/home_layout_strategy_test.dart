import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konekto/layout/home_layout_engine.dart';
import 'package:konekto/layout/home_layout_strategy.dart';
import 'package:konekto/layout/layout_registry.dart';
import 'package:konekto/modules/module_definition.dart';
import 'package:konekto/templates/guest_template_registry.dart';
import 'package:konekto/templates/shared/guest_template_theme.dart';

ModuleDefinition _module(String id, String name) => ModuleDefinition(
      id: id,
      name: name,
      description: 'descrição de $name',
      category: ModuleCategory.core,
      icon: 'home',
      implemented: true,
    );

final _theme = GuestTemplateTheme(
  colors: const ColorScheme.light(),
  displayFontFamily: GoogleFonts.notoSans().fontFamily!,
  bodyFontFamily: GoogleFonts.notoSans().fontFamily!,
  radiusSm: 4,
  radiusDefault: 8,
  radiusMd: 12,
  radiusLg: 16,
  radiusXl: 24,
);

void main() {
  setUp(() => LayoutRegistry.resetForTesting());

  group('VerticalListLayoutStrategy', () {
    testWidgets('renders one card per module, stacked vertically', (tester) async {
      final modules = [_module('a', 'Módulo A'), _module('b', 'Módulo B')];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) => const VerticalListLayoutStrategy().build(context, modules, _theme)),
        ),
      );

      expect(find.text('Módulo A'), findsOneWidget);
      expect(find.text('Módulo B'), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders nothing for an empty module list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Builder(builder: (context) => const VerticalListLayoutStrategy().build(context, const [], _theme))),
      );
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  group('HeroCarouselLayoutStrategy', () {
    testWidgets('renders the first module as hero and the rest in a horizontal list', (tester) async {
      final modules = [_module('hero', 'Destaque'), _module('b', 'Carrossel B'), _module('c', 'Carrossel C')];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) => const HeroCarouselLayoutStrategy().build(context, modules, _theme)),
        ),
      );

      expect(find.text('Destaque'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Carrossel B'), findsOneWidget);
      expect(find.text('Carrossel C'), findsOneWidget);
    });

    testWidgets('renders only the hero when there is a single module (no carousel)', (tester) async {
      final modules = [_module('hero', 'Só destaque')];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) => const HeroCarouselLayoutStrategy().build(context, modules, _theme)),
        ),
      );

      expect(find.text('Só destaque'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });
  });

  group('MinimalDashboardLayoutStrategy', () {
    testWidgets('renders modules in a 2-column grid', (tester) async {
      final modules = [_module('a', 'Card A'), _module('b', 'Card B')];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) => const MinimalDashboardLayoutStrategy().build(context, modules, _theme)),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsOneWidget);
    });
  });

  group('homeLayoutStrategyFor', () {
    test('maps aura/bosque to VerticalListLayoutStrategy', () {
      expect(homeLayoutStrategyFor(GuestTemplateId.aura), isA<VerticalListLayoutStrategy>());
      expect(homeLayoutStrategyFor(GuestTemplateId.bosque), isA<VerticalListLayoutStrategy>());
    });

    test('maps elite/pulse to MinimalDashboardLayoutStrategy', () {
      expect(homeLayoutStrategyFor(GuestTemplateId.elite), isA<MinimalDashboardLayoutStrategy>());
      expect(homeLayoutStrategyFor(GuestTemplateId.pulse), isA<MinimalDashboardLayoutStrategy>());
    });

    test('maps horizon to HeroCarouselLayoutStrategy', () {
      expect(homeLayoutStrategyFor(GuestTemplateId.horizon), isA<HeroCarouselLayoutStrategy>());
    });
  });
}
