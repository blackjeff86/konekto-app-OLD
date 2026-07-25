import 'package:flutter/material.dart';
import 'package:konekto_portal/theme/konekto_brand.dart';

/// Rótulos curtos dos dias da semana em ordem ISO (1=segunda...7=domingo) —
/// mesmo valor guardado tanto em `ServiceItem.availableDaysOfWeek` quanto
/// em `Service.operatingDaysOfWeek`.
const List<String> weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

/// Seletor de dias da semana compartilhado — usado tanto no agendamento
/// por item (spa/eventos/passeios) quanto no horário de funcionamento de
/// um serviço inteiro (room service/restaurante). Puramente apresentacional:
/// quem chama decide o que `selectedDays`/`onToggleDay` significam.
class WeekdayChips extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onToggleDay;

  const WeekdayChips({super.key, required this.selectedDays, required this.onToggleDay});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var day = 1; day <= 7; day++)
          FilterChip(
            label: Text(weekdayLabels[day - 1]),
            selected: selectedDays.contains(day),
            onSelected: (_) => onToggleDay(day),
            selectedColor: KonektoBrand.gold.withValues(alpha: 0.25),
            checkmarkColor: KonektoBrand.goldLight,
            labelStyle: KonektoBrand.body(fontSize: 12, color: KonektoBrand.cream),
            backgroundColor: Colors.white.withValues(alpha: 0.03),
            side: const BorderSide(color: KonektoBrand.borderStrong),
          ),
      ],
    );
  }
}
