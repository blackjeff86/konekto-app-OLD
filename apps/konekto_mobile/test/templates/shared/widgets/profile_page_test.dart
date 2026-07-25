import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/templates/shared/widgets/profile_page.dart';
import 'package:konekto/theme/guest_app_theme.dart';

final _theme = GuestAppTheme.fromTenantConfig(const {});

Future<void> _pumpProfilePage(
  WidgetTester tester, {
  VoidCallback? onOpenLoyalty,
  VoidCallback? onOpenWallet,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProfilePage(
        theme: _theme,
        guestName: 'Ana Souza',
        roomNumber: '204',
        onOpenLoyalty: onOpenLoyalty,
        onOpenWallet: onOpenWallet,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('does not show Loyalty/Wallet rows when the callbacks are null (aura/bosque today)', (tester) async {
    await _pumpProfilePage(tester);

    expect(find.text('Programa de fidelidade'), findsNothing);
    expect(find.text('Carteira digital'), findsNothing);
  });

  testWidgets('shows the Loyalty row and triggers its callback on tap', (tester) async {
    var tapped = false;
    await _pumpProfilePage(tester, onOpenLoyalty: () => tapped = true);

    expect(find.text('Programa de fidelidade'), findsOneWidget);
    await tester.tap(find.text('Programa de fidelidade'));
    expect(tapped, isTrue);
  });

  testWidgets('shows the Wallet row independently of the Loyalty row', (tester) async {
    await _pumpProfilePage(tester, onOpenWallet: () {});

    expect(find.text('Carteira digital'), findsOneWidget);
    expect(find.text('Programa de fidelidade'), findsNothing);
  });
}
