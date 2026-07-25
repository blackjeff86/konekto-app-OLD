import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/modules/module_registry.dart';
import 'package:konekto/navigation/navigation_engine.dart';
import 'package:konekto/navigation/presentation_mode.dart';

const _context = ModuleRenderContext(tenantId: 'hotel_1');

Future<void> _pumpTriggerButton(WidgetTester tester, {required VoidCallback onPressed}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        endDrawer: const Drawer(child: Text('drawer aberto')),
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: onPressed,
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => moduleRegistry.clear());

  testWidgets('present is a no-op when the module has no registry entry', (tester) async {
    await _pumpTriggerButton(
      tester,
      onPressed: () {},
    );
    // chama direto sem builder registrado — não deve lançar nem navegar
    final context = tester.element(find.byType(ElevatedButton));
    await NavigationEngine.present(context, screenId: 'unregistered_module', moduleContext: _context);
    await tester.pumpAndSettle();

    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('present is a no-op when the entry has no screenBuilder', (tester) async {
    moduleRegistry['loyalty'] = const ModuleRegistryEntry(moduleId: 'loyalty');
    await _pumpTriggerButton(tester, onPressed: () {});
    final context = tester.element(find.byType(ElevatedButton));

    await NavigationEngine.present(context, screenId: 'loyalty', moduleContext: _context);
    await tester.pumpAndSettle();

    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('present with PresentationMode.page pushes a new route', (tester) async {
    moduleRegistry['wallet'] = ModuleRegistryEntry(
      moduleId: 'wallet',
      screenBuilder: (context, ctx) => const Scaffold(body: Text('Tela da Carteira')),
    );
    await _pumpTriggerButton(tester, onPressed: () {});
    final context = tester.element(find.byType(ElevatedButton));

    unawaited(NavigationEngine.present(context, screenId: 'wallet', moduleContext: _context));
    await tester.pumpAndSettle();

    expect(find.text('Tela da Carteira'), findsOneWidget);
  });

  testWidgets('present with PresentationMode.modal shows a dialog', (tester) async {
    moduleRegistry['promotions'] = ModuleRegistryEntry(
      moduleId: 'promotions',
      defaultPresentation: PresentationMode.modal,
      screenBuilder: (context, ctx) => const AlertDialog(content: Text('Promoção em destaque')),
    );
    await _pumpTriggerButton(tester, onPressed: () {});
    final context = tester.element(find.byType(ElevatedButton));

    unawaited(NavigationEngine.present(context, screenId: 'promotions', moduleContext: _context));
    await tester.pumpAndSettle();

    expect(find.text('Promoção em destaque'), findsOneWidget);
  });

  testWidgets('present with PresentationMode.bottomSheet shows a bottom sheet', (tester) async {
    moduleRegistry['room_service'] = ModuleRegistryEntry(
      moduleId: 'room_service',
      defaultPresentation: PresentationMode.bottomSheet,
      screenBuilder: (context, ctx) => const Text('Adicionar ao pedido'),
    );
    await _pumpTriggerButton(tester, onPressed: () {});
    final context = tester.element(find.byType(ElevatedButton));

    unawaited(NavigationEngine.present(context, screenId: 'room_service', moduleContext: _context));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar ao pedido'), findsOneWidget);
  });

  testWidgets('overrideMode takes precedence over the registry default presentation', (tester) async {
    moduleRegistry['loyalty'] = ModuleRegistryEntry(
      moduleId: 'loyalty',
      defaultPresentation: PresentationMode.page,
      screenBuilder: (context, ctx) => const AlertDialog(content: Text('Fidelidade como modal')),
    );
    await _pumpTriggerButton(tester, onPressed: () {});
    final context = tester.element(find.byType(ElevatedButton));

    unawaited(
      NavigationEngine.present(context, screenId: 'loyalty', moduleContext: _context, overrideMode: PresentationMode.modal),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fidelidade como modal'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });
}
