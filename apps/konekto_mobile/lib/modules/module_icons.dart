import 'package:flutter/material.dart';

/// Nome de ícone Material (string, como vem do Module Catalog e do
/// catálogo de Serviços) -> `IconData`. Superset do `_iconMapping` de
/// `app/tenants/services_page.dart` — fonte única a partir daqui; a
/// migração de `services_page.dart` pra usar este mapa acontece na Fase 11
/// (quando Serviços vira module-driven), não nesta fase.
const Map<String, IconData> kModuleIconMapping = {
  'home': Icons.home,
  'history': Icons.history,
  'person': Icons.person,
  'person_outline': Icons.person_outline,
  'settings': Icons.settings,
  'restaurant': Icons.restaurant,
  'spa': Icons.spa,
  'sports_soccer': Icons.sports_soccer,
  'event': Icons.event,
  'event_note': Icons.event_note,
  'event_note_outlined': Icons.event_note_outlined,
  'widgets': Icons.widgets,
  'grid_view': Icons.grid_view,
  'grid_view_outlined': Icons.grid_view_outlined,
  'room_service': Icons.room_service,
  'map': Icons.map,
  'book_online': Icons.book_online,
  'pedal_bike': Icons.pedal_bike,
  'local_laundry_service': Icons.local_laundry_service,
  'pool': Icons.pool,
  'fitness_center': Icons.fitness_center,
  'local_bar': Icons.local_bar,
  'directions_car': Icons.directions_car,
  'directions_walk': Icons.directions_walk,
  'celebration': Icons.celebration,
  'local_shipping': Icons.local_shipping,
  'pets': Icons.pets,
  'child_care': Icons.child_care,
  'info': Icons.info,
  'chat_bubble_outline': Icons.chat_bubble_outline,
  'notifications_none': Icons.notifications_none,
  'notifications_active': Icons.notifications_active,
  'account_balance_wallet': Icons.account_balance_wallet,
  'payment': Icons.payment,
  'receipt_long': Icons.receipt_long,
  'local_offer': Icons.local_offer,
  'stars': Icons.stars,
  'star_rate': Icons.star_rate,
  'login': Icons.login,
  'logout': Icons.logout,
  'translate': Icons.translate,
  'help_outline': Icons.help_outline,
  'support': Icons.support,
  'support_agent': Icons.support_agent,
  'local_parking': Icons.local_parking,
};

IconData resolveModuleIcon(String iconName) => kModuleIconMapping[iconName] ?? Icons.miscellaneous_services;
