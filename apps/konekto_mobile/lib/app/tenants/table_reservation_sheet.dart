import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Data/hora e tipo de mesa escolhidos pelo hóspede no
/// [showTableReservationSheet].
class TableReservationResult {
  final DateTime dateTime;
  /// `null` quando o restaurante não tem tipos de mesa cadastrados
  /// (comportamento legado, sem checagem de capacidade).
  final String? tableTypeId;

  const TableReservationResult({
    required this.dateTime,
    required this.tableTypeId,
  });
}

/// Um tipo de mesa com a disponibilidade calculada pro instante escolhido —
/// devolvido por `GET .../table-availability`.
class TableTypeAvailability {
  final String id;
  final String? label;
  final int seats;
  final int availableQuantity;

  const TableTypeAvailability({
    required this.id,
    this.label,
    required this.seats,
    required this.availableQuantity,
  });

  String get displayLabel => label ?? 'Mesa de $seats lugares';
}

/// Modal de reserva de mesa de restaurante — diferente de
/// [showBookingSheet] (usado por atividades): aqui não existe grade de
/// horários com duração fixa, o hóspede escolhe dia/hora livremente (dentro
/// do horário de funcionamento do restaurante, se configurado) e, assim
/// que os dois estão definidos, vê a disponibilidade real de cada tipo de
/// mesa naquele instante exato pra escolher.
Future<TableReservationResult?> showTableReservationSheet(
  BuildContext context, {
  required String itemName,
  required String fontFamily,
  required Color primaryColor,
  required Color backgroundColor,
  required Color bodyTextColor,
  String? headlineFontFamily,
  String? confirmLabel,
  required Future<Map<String, dynamic>> Function(DateTime scheduledFor)
  loadTableAvailability,
}) {
  return showModalBottomSheet<TableReservationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TableReservationSheet(
      itemName: itemName,
      fontFamily: fontFamily,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      bodyTextColor: bodyTextColor,
      headlineFontFamily: headlineFontFamily ?? fontFamily,
      confirmLabel: confirmLabel,
      loadTableAvailability: loadTableAvailability,
    ),
  );
}

class _TableReservationSheet extends StatefulWidget {
  final String itemName;
  final String fontFamily;
  final Color primaryColor;
  final Color backgroundColor;
  final Color bodyTextColor;
  final String headlineFontFamily;
  final String? confirmLabel;
  final Future<Map<String, dynamic>> Function(DateTime scheduledFor)
  loadTableAvailability;

  const _TableReservationSheet({
    required this.itemName,
    required this.fontFamily,
    required this.primaryColor,
    required this.backgroundColor,
    required this.bodyTextColor,
    required this.headlineFontFamily,
    required this.confirmLabel,
    required this.loadTableAvailability,
  });

  @override
  State<_TableReservationSheet> createState() =>
      _TableReservationSheetState();
}

class _TableReservationSheetState extends State<_TableReservationSheet> {
  late DateTime _date;
  late TimeOfDay _time;

  bool _isLoading = false;
  String? _error;
  List<TableTypeAvailability>? _tableTypes;
  String? _selectedTableTypeId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _time = const TimeOfDay(hour: 19, minute: 0);
    _loadAvailability();
  }

  DateTime get _scheduledFor =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedTableTypeId = null;
    });
    try {
      final json = await widget.loadTableAvailability(_scheduledFor);
      if (!mounted) return;
      if (json['ok'] != true) {
        setState(() {
          _error = (json['error'] as String?) == 'service_closed'
              ? 'Fechado nesse horário.'
              : 'Não foi possível verificar a disponibilidade.';
          _tableTypes = null;
        });
        return;
      }
      final rawTypes = json['tableTypes'] as List<dynamic>? ?? const [];
      setState(() {
        _tableTypes = rawTypes
            .map(
              (raw) => TableTypeAvailability(
                id: (raw as Map<String, dynamic>)['id'] as String,
                label: raw['label'] as String?,
                seats: raw['seats'] as int,
                availableQuantity: raw['availableQuantity'] as int,
              ),
            )
            .toList();
      });
    } on Exception {
      if (!mounted) return;
      setState(
        () => _error = 'Não foi possível verificar a disponibilidade.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year, now.month, now.day))
          ? now
          : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _loadAvailability();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
    await _loadAvailability();
  }

  void _confirm() {
    Navigator.of(context).pop(
      TableReservationResult(
        dateTime: _scheduledFor,
        tableTypeId: _selectedTableTypeId,
      ),
    );
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
    // Restaurante sem tipos de mesa cadastrados: reserva continua livre,
    // sem exigir escolha (comportamento legado, sem checagem de
    // capacidade). Com tipos cadastrados, precisa escolher um com vaga.
    final canConfirm =
        !_isLoading &&
        _error == null &&
        ((_tableTypes?.isEmpty ?? false) || _selectedTableTypeId != null);
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
                style: GoogleFonts.getFont(
                  widget.headlineFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _ReservationField(
                icon: Icons.calendar_today_outlined,
                label: 'Dia',
                value: _formatDate(context, _date),
                fontFamily: widget.fontFamily,
                primaryColor: widget.primaryColor,
                bodyTextColor: widget.bodyTextColor,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              _ReservationField(
                icon: Icons.access_time,
                label: 'Horário',
                value: _formatTime(_time),
                fontFamily: widget.fontFamily,
                primaryColor: widget.primaryColor,
                bodyTextColor: widget.bodyTextColor,
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              _TableTypeGrid(
                isLoading: _isLoading,
                error: _error,
                tableTypes: _tableTypes,
                selectedTableTypeId: _selectedTableTypeId,
                fontFamily: widget.fontFamily,
                primaryColor: widget.primaryColor,
                bodyTextColor: widget.bodyTextColor,
                onSelect: (id) => setState(() => _selectedTableTypeId = id),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.confirmLabel ?? 'Reservar',
                    style: GoogleFonts.getFont(widget.fontFamily, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final VoidCallback onTap;

  const _ReservationField({
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
            Text(
              label,
              style: GoogleFonts.getFont(
                fontFamily,
                fontSize: 13,
                color: bodyTextColor,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.getFont(
                fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: bodyTextColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grade de tipos de mesa disponíveis pro instante escolhido — os
/// esgotados aparecem desabilitados/riscados, mesmo visual já usado nos
/// horários de atividade (`_SlotGrid`/`_SlotChip` em `booking_sheet.dart`).
class _TableTypeGrid extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<TableTypeAvailability>? tableTypes;
  final String? selectedTableTypeId;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final ValueChanged<String> onSelect;

  const _TableTypeGrid({
    required this.isLoading,
    required this.error,
    required this.tableTypes,
    required this.selectedTableTypeId,
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
      return Text(
        error!,
        style: GoogleFonts.getFont(fontFamily, fontSize: 13, color: bodyTextColor),
      );
    }
    final types = tableTypes ?? const [];
    if (types.isEmpty) {
      // Restaurante sem tipos de mesa cadastrados — reserva continua livre,
      // sem escolha de tipo (comportamento legado).
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tableType in types)
          _TableTypeChip(
            tableType: tableType,
            isSelected: tableType.id == selectedTableTypeId,
            fontFamily: fontFamily,
            primaryColor: primaryColor,
            bodyTextColor: bodyTextColor,
            onTap: tableType.availableQuantity > 0
                ? () => onSelect(tableType.id)
                : null,
          ),
      ],
    );
  }
}

class _TableTypeChip extends StatelessWidget {
  final TableTypeAvailability tableType;
  final bool isSelected;
  final String fontFamily;
  final Color primaryColor;
  final Color bodyTextColor;
  final VoidCallback? onTap;

  const _TableTypeChip({
    required this.tableType,
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
            color: isDisabled
                ? bodyTextColor.withValues(alpha: 0.15)
                : primaryColor.withValues(alpha: isSelected ? 1 : 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tableType.displayLabel,
              style: GoogleFonts.getFont(
                fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isDisabled
                    ? bodyTextColor.withValues(alpha: 0.35)
                    : primaryColor,
                decoration: isDisabled
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            Text(
              isDisabled
                  ? 'Esgotado'
                  : '${tableType.availableQuantity} disponível(is)',
              style: GoogleFonts.getFont(
                fontFamily,
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : bodyTextColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
