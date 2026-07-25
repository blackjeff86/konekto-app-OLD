import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:konekto/l10n/app_localizations.dart';

/// Data/hora escolhida pelo hóspede no [showBookingSheet].
class BookingResult {
  final DateTime dateTime;

  const BookingResult({required this.dateTime});
}

/// Um horário candidato pra reserva, gerado pelo backend a partir da
/// configuração de agendamento do item (`ServiceItem.durationMinutes` etc)
/// — `available: false` = já está no limite de capacidade naquele horário,
/// mostrado desabilitado em vez de simplesmente omitido, pro hóspede
/// entender que o horário existe mas está cheio.
class TimeSlot {
  final String time; // "HH:mm"
  final bool available;

  const TimeSlot({required this.time, required this.available});
}

/// Modal de agendamento — usado por todo item que não é Serviço de Quarto
/// (restaurantes, spa, eventos, passeios): escolhe dia e horário, depois
/// confirma a reserva. Diferente do [showOrderQuantityNoteSheet] (sem
/// quantidade/observação, já que o que importa aqui é o horário).
///
/// Dois modos de escolher o horário:
/// - **Livre** (padrão, `schedulingEnabled: false`): `showTimePicker` sem
///   restrição — comportamento legado, usado sempre que o item não tem
///   agendamento configurado no portal (`durationMinutes == null`).
/// - **Com agendamento** (`schedulingEnabled: true`, precisa de
///   [loadAvailability]): mostra só os horários que o backend calculou como
///   realmente disponíveis pra aquele dia, desabilitando os que já estão no
///   limite de capacidade — nunca deixa o hóspede digitar/escolher um
///   horário livre nesse modo.
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
  String? headlineFontFamily,
  DateTime? initialDateTime,
  String? confirmLabel,
  bool schedulingEnabled = false,
  Future<List<TimeSlot>> Function(DateTime date)? loadAvailability,
}) {
  assert(
    !schedulingEnabled || loadAvailability != null,
    'loadAvailability é obrigatório quando schedulingEnabled é true.',
  );
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
      headlineFontFamily: headlineFontFamily ?? fontFamily,
      initialDateTime: initialDateTime,
      confirmLabel: confirmLabel,
      schedulingEnabled: schedulingEnabled,
      loadAvailability: loadAvailability,
    ),
  );
}

class _BookingSheet extends StatefulWidget {
  final String itemName;
  final String fontFamily;
  final Color primaryColor;
  final Color backgroundColor;
  final Color bodyTextColor;
  final String headlineFontFamily;
  final DateTime? initialDateTime;
  final String? confirmLabel;
  final bool schedulingEnabled;
  final Future<List<TimeSlot>> Function(DateTime date)? loadAvailability;

  const _BookingSheet({
    required this.itemName,
    required this.fontFamily,
    required this.primaryColor,
    required this.backgroundColor,
    required this.bodyTextColor,
    required this.headlineFontFamily,
    required this.initialDateTime,
    required this.confirmLabel,
    required this.schedulingEnabled,
    required this.loadAvailability,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late DateTime _date;
  late TimeOfDay _time;

  // Só usado no modo com agendamento (widget.schedulingEnabled).
  List<TimeSlot>? _slots;
  bool _isLoadingSlots = false;
  String? _slotsError;
  String? _selectedSlotTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDateTime;
    final now = DateTime.now();
    _date = initial != null ? DateTime(initial.year, initial.month, initial.day) : DateTime(now.year, now.month, now.day);
    _time = initial != null ? TimeOfDay(hour: initial.hour, minute: initial.minute) : const TimeOfDay(hour: 19, minute: 0);
    if (widget.schedulingEnabled) {
      _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _slotsError = null;
      _selectedSlotTime = null;
    });
    try {
      final slots = await widget.loadAvailability!(_date);
      if (!mounted) return;
      setState(() => _slots = slots);
    } on Exception {
      if (!mounted) return;
      setState(() => _slotsError = 'Não foi possível carregar os horários disponíveis.');
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year, now.month, now.day)) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    if (widget.schedulingEnabled) {
      await _loadSlots();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  TimeOfDay _parseSlotTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _confirm() {
    final TimeOfDay time;
    if (widget.schedulingEnabled) {
      final selected = _selectedSlotTime;
      if (selected == null) return;
      time = _parseSlotTime(selected);
    } else {
      time = _time;
    }
    final dateTime = DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);
    Navigator.of(context).pop(BookingResult(dateTime: dateTime));
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirmLabel = widget.confirmLabel ?? l10n.reserveButton;
    final canConfirm = !widget.schedulingEnabled || _selectedSlotTime != null;
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
                style: GoogleFonts.getFont(widget.headlineFontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: widget.primaryColor),
              ),
              const SizedBox(height: 20),
              _BookingField(
                icon: Icons.calendar_today_outlined,
                label: l10n.dayLabel,
                value: _formatDate(context, _date),
                fontFamily: widget.fontFamily,
                primaryColor: widget.primaryColor,
                bodyTextColor: widget.bodyTextColor,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              if (widget.schedulingEnabled)
                _SlotGrid(
                  isLoading: _isLoadingSlots,
                  error: _slotsError,
                  slots: _slots,
                  selectedTime: _selectedSlotTime,
                  fontFamily: widget.fontFamily,
                  primaryColor: widget.primaryColor,
                  bodyTextColor: widget.bodyTextColor,
                  onSelect: (time) => setState(() => _selectedSlotTime = time),
                )
              else
                _BookingField(
                  icon: Icons.access_time,
                  label: l10n.timeLabel,
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
                  onPressed: canConfirm ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(confirmLabel, style: GoogleFonts.getFont(widget.fontFamily, fontSize: 16)),
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

/// Grade de horários do modo com agendamento — só os horários que o
/// backend devolveu ficam clicáveis; os cheios aparecem esmaecidos.
class _SlotGrid extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<TimeSlot>? slots;
  final String? selectedTime;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final ValueChanged<String> onSelect;

  const _SlotGrid({
    required this.isLoading,
    required this.error,
    required this.slots,
    required this.selectedTime,
    required this.fontFamily,
    required this.primaryColor,
    required this.bodyTextColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
          ),
        ),
      );
    }
    if (error != null) {
      return Text(error!, style: GoogleFonts.getFont(fontFamily, fontSize: 13, color: bodyTextColor));
    }
    final currentSlots = slots ?? const [];
    if (currentSlots.isEmpty) {
      return Text(
        'Nenhum horário disponível nesse dia.',
        style: GoogleFonts.getFont(fontFamily, fontSize: 13, color: bodyTextColor),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final slot in currentSlots)
          _SlotChip(
            slot: slot,
            isSelected: slot.time == selectedTime,
            fontFamily: fontFamily,
            primaryColor: primaryColor,
            bodyTextColor: bodyTextColor,
            onTap: slot.available ? () => onSelect(slot.time) : null,
          ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final VoidCallback? onTap;

  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.fontFamily,
    required this.primaryColor,
    required this.bodyTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDisabled ? bodyTextColor.withValues(alpha: 0.15) : primaryColor.withValues(alpha: isSelected ? 1 : 0.5),
          ),
        ),
        child: Text(
          slot.time,
          style: GoogleFonts.getFont(
            fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDisabled
                ? bodyTextColor.withValues(alpha: 0.35)
                : primaryColor,
            decoration: isDisabled ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
