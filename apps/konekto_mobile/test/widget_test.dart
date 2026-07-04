import 'package:flutter_test/flutter_test.dart';

import 'package:konekto/main.dart';
import 'package:konekto/app/home_konekto/home_konekto_page.dart';

void main() {
  testWidgets('MyApp starts on the hotel access screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeKonektoPage), findsOneWidget);
    expect(find.text('Código de Acesso do Hotel'), findsOneWidget);
  });
}
