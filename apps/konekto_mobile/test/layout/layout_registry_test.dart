import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/layout/layout_registry.dart';
import 'package:konekto/layout/layout_variant.dart';
import 'package:konekto/modules/module_definition.dart';

const _restaurant = ModuleDefinition(
  id: 'restaurant',
  name: 'Restaurantes',
  description: 'Cardápio e reservas de mesa.',
  category: ModuleCategory.hospitalidade,
  icon: 'restaurant',
  implemented: true,
);

void main() {
  setUp(() => LayoutRegistry.resetForTesting());

  test('resolve returns the registered variant for a module', () {
    LayoutRegistry.register(
      'restaurant',
      LayoutVariant(id: 'hero_card', builder: (context, module) => const Text('hero de restaurante')),
    );

    final variant = LayoutRegistry.resolve('restaurant', 'hero_card');

    expect(variant.id, 'hero_card');
  });

  test('hasVariant reports whether a specific variant was registered', () {
    LayoutRegistry.register('restaurant', LayoutVariant(id: 'hero_card', builder: (context, module) => const SizedBox()));

    expect(LayoutRegistry.hasVariant('restaurant', 'hero_card'), isTrue);
    expect(LayoutRegistry.hasVariant('restaurant', 'carousel_card'), isFalse);
    expect(LayoutRegistry.hasVariant('promotions', 'banner'), isFalse);
  });

  test('resolve falls back to a generic compact card when the module has no variant registered', () {
    final variant = LayoutRegistry.resolve('loyalty', 'dashboard_card');
    expect(variant.id, 'dashboard_card');
    expect(LayoutRegistry.hasVariant('loyalty', 'dashboard_card'), isFalse);
  });

  testWidgets('the generic fallback card renders the module name and description', (tester) async {
    final variant = LayoutRegistry.resolve('restaurant', 'compact_card');
    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: (context) => variant.builder(context, _restaurant))),
    );

    expect(find.text('Restaurantes'), findsOneWidget);
    expect(find.text('Cardápio e reservas de mesa.'), findsOneWidget);
  });

  testWidgets('a registered variant renders its own custom builder instead of the fallback', (tester) async {
    LayoutRegistry.register(
      'restaurant',
      LayoutVariant(id: 'hero_card', builder: (context, module) => Text('Hero de ${module.name}')),
    );
    final variant = LayoutRegistry.resolve('restaurant', 'hero_card');

    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: (context) => variant.builder(context, _restaurant))),
    );

    expect(find.text('Hero de Restaurantes'), findsOneWidget);
  });

  test('registerAll registers multiple variants for the same module at once', () {
    LayoutRegistry.registerAll('promotions', [
      LayoutVariant(id: 'banner', builder: (context, module) => const SizedBox()),
      LayoutVariant(id: 'grid', builder: (context, module) => const SizedBox()),
    ]);

    expect(LayoutRegistry.hasVariant('promotions', 'banner'), isTrue);
    expect(LayoutRegistry.hasVariant('promotions', 'grid'), isTrue);
  });
}
