import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data/hora escolhida pelo hóspede no [showBookingSheet].
class BookingResult {
  final DateTime dateTime;

  const BookingResult({required this.dateTime});
}

/// Modal de agendamento — usado por todo item que não é Serviço de Quarto
/// (restaurantes, spa, eventos, passeios): escolhe dia e horário, depois
/// confirma a reserva. Diferente do [showOrderQuantityNoteSheet] (sem
/// quantidade/observação, já que o que importa aqui é o horário).
///
/// O seletor de "pessoa alocada no quarto" (marido/esposa/filhos com
/// códigos próprios) ainda não entra aqui — depende da entidade Stay
/// (reserva de quarto), planejada pra uma sessão futura. Por enquanto a
/// reserva sempre fica em nome de quem está logado.
Future<BookingResult?> showBookingSheet(
  BuildContext context, {
  required String itemName,
  required String fontFamily,
  required Color primaryColor,
  required Color backgroundColor,
  required Color bodyTextColor,
  DateTime? initialDateTime,
  String confirmLabel = 'Reservar',
}) {
  return showModalBottomSheet<BookingResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _BookingSheet(
      itemName: itemName,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      bodyTextColor: bodyTextColor,
      initialDateTime: initialDateTime,
      confirmLabel: confirmLabel,
    ),
  );
}

class _BookingSheet extends StatefulWidget {
  final String itemName;
  final String fontFamily;
  final Color primaryColor;
  final Color backgroundColor;
  final Color bodyTextColor;
  final DateTime? initialDateTime;
  final String confirmLabel;

  const _BookingSheet({
    required this.itemName,
    required this.fontFamily,
    required this.primaryColor,
    required this.backgroundColor,
    required this.bodyTextColor,
    required this.initialDateTime,
    required this.confirmLabel,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDateTime;
    final now = DateTime.now();
    _date = initial != null ? DateTime(initial.year, initial.month, initial.day) : DateTime(now.year, now.month, now.day);
    _time = initial != null ? TimeOfDay(hour: initial.hour, minute: initial.minute) : const TimeOfDay(hour: 19, minute: 0);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year, now.month, now.day)) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _confirm() {
    final dateTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    Navigator.of(context).pop(BookingResult(dateTime: dateTime));
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: widget.bodyTextColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.itemName,
                style: GoogleFonts.getFont(widget.fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: widget.primaryColor),
              ),
              const SizedBox(height: 20),
              _BookingField(
                icon: Icons.calendar_today_outlined,
                label: 'Dia',
                value: _formatDate(_date),
                fontFamily: widget.fontFamily,
                primaryColor: widget.primaryColor,
                bodyTextColor: widget.bodyTextColor,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              _BookingField(
                icon: Icons.access_time,
                label: 'Horário',
                value: _formatTime(_time),
                fontFamily: widget.fontFamily,
                primaryColor: widget.primaryColor,
                bodyTextColor: widget.bodyTextColor,
                onTap: _pickTime,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(widget.confirmLabel, style: GoogleFonts.getFont(widget.fontFamily, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final VoidCallback onTap;

  const _BookingField({
    required this.icon,
    required this.label,
    required this.value,
    required this.fontFamily,
    required this.primaryColor,
    required this.bodyTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bodyTextColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.getFont(fontFamily, fontSize: 13, color: bodyTextColor)),
            const Spacer(),
            Text(value, style: GoogleFonts.getFont(fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: bodyTextColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
