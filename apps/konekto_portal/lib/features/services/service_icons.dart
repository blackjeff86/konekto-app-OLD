import 'package:flutter/material.dart';

/// Ícones disponíveis pro gerente escolher ao criar um serviço, e o mapa
/// pra renderizar o `icon` (string) salvo na API de volta pra um
/// `IconData`. Não precisa cobrir todo o Material Icons — só um conjunto
/// razoável pros casos de uso mais comuns; `helpOutline` é o fallback pra
/// nomes desconhecidos (ex: um serviço criado antes de um ícone ser
/// removido dessa lista).
const Map<String, IconData> kServiceIconOptions = {
  'room_service': Icons.room_service_outlined,
  'spa': Icons.spa_outlined,
  'restaurant': Icons.restaurant_outlined,
  'event': Icons.event_outlined,
  'sports_soccer': Icons.sports_soccer_outlined,
  'pedal_bike': Icons.pedal_bike_outlined,
  'local_laundry_service': Icons.local_laundry_service_outlined,
  'pool': Icons.pool_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'local_bar': Icons.local_bar_outlined,
  'directions_car': Icons.directions_car_outlined,
  'celebration': Icons.celebration_outlined,
  'local_shipping': Icons.local_shipping_outlined,
  'pets': Icons.pets_outlined,
  'child_care': Icons.child_care_outlined,
};

IconData serviceIconFor(String iconName) {
  return kServiceIconOptions[iconName] ?? Icons.help_outline;
}
