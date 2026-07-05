import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

// Nota: StaffGate/RedirectToLoginPage usam package:web (window.location,
// history) pra consumir o token da URL e redirecionar pro login.html do
// site — essas APIs só existem em runtime de navegador, então testá-las
// exigiria rodar `flutter test --platform chrome` com mocks de
// SharedPreferences/http. Esse smoke test cobre só o que é seguro na VM.
void main() {
  testWidgets('KonektoMark renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: KonektoMark(size: 40)))),
    );

    expect(find.byType(KonektoMark), findsOneWidget);
  });
}
