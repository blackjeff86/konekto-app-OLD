import 'package:flutter/material.dart';
import 'package:konekto/l10n/app_localizations.dart';
import 'package:konekto/l10n/locale_controller.dart';
import 'package:konekto/theme/guest_app_theme.dart';

class ProfilePage extends StatelessWidget {
  final GuestAppTheme theme;
  final String guestName;
  final String roomNumber;
  final VoidCallback? onEndSession;
  final VoidCallback? onOpenStayBill;

  const ProfilePage({
    super.key,
    required this.theme,
    required this.guestName,
    required this.roomNumber,
    this.onEndSession,
    this.onOpenStayBill,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String initials = guestName.trim().isNotEmpty
        ? guestName.trim().split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase()
        : '?';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent,
                  boxShadow: [BoxShadow(color: theme.accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: Text(initials, style: theme.headline(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(guestName, textAlign: TextAlign.center, style: theme.headline(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(theme.hotelName, textAlign: TextAlign.center, style: theme.body(color: theme.mutedColor, fontSize: 14)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
                boxShadow: theme.tokens.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
                    child: Icon(Icons.meeting_room_outlined, color: theme.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.profileRoom, style: theme.body(color: theme.mutedColor, fontSize: 13)),
                      Text(roomNumber, style: theme.headline(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onOpenStayBill,
              borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
                  boxShadow: theme.tokens.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentSoft),
                      child: Icon(Icons.receipt_long_outlined, color: theme.accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(l10n.myAccountTile, style: theme.body(fontWeight: FontWeight.w600))),
                    Icon(Icons.chevron_right_rounded, color: theme.mutedColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(theme.tokens.cardRadius),
                boxShadow: theme.tokens.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.profileLanguage, style: theme.body(color: theme.mutedColor, fontSize: 13)),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<Locale>(
                    valueListenable: LocaleController.instance.locale,
                    builder: (context, currentLocale, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _LanguageOption(
                              label: 'Português',
                              selected: currentLocale.languageCode == 'pt',
                              theme: theme,
                              onTap: () => LocaleController.instance.setLocale(const Locale('pt')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LanguageOption(
                              label: 'English',
                              selected: currentLocale.languageCode == 'en',
                              theme: theme,
                              onTap: () => LocaleController.instance.setLocale(const Locale('en')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LanguageOption(
                              label: 'Español',
                              selected: currentLocale.languageCode == 'es',
                              theme: theme,
                              onTap: () => LocaleController.instance.setLocale(const Locale('es')),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (onEndSession != null)
              OutlinedButton.icon(
                onPressed: onEndSession,
                icon: Icon(Icons.logout_rounded, color: theme.accent),
                label: Text(l10n.profileEndSession, style: theme.body(color: theme.accent, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.accent.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.tokens.cardRadius)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final GuestAppTheme theme;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.accent : theme.accentSoft,
          borderRadius: BorderRadius.circular(theme.tokens.pillRadius),
          border: selected ? null : Border.all(color: theme.borderColor),
        ),
        child: Text(
          label,
          style: theme.body(
            color: selected ? Colors.white : theme.mutedColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
