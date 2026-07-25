import 'package:flutter/material.dart';
import 'package:konekto/templates/shared/widgets/notification_count_badge.dart';
import 'package:konekto/theme/guest_app_theme.dart';

/// Botão circular do header (sino de notificações, avatar) com badge
/// opcional de contagem — igual em todos os templates.
class HeaderIconButton extends StatelessWidget {
  final GuestAppTheme theme;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const HeaderIconButton({
    super.key,
    required this.theme,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: theme.accent.withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: theme.accent),
          ),
          if (badgeCount > 0) Positioned(top: -2, right: -2, child: NotificationCountBadge(count: badgeCount, theme: theme)),
        ],
      ),
    );
  }
}
