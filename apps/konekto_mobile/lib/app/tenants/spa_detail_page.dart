import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class SpaDetailPage extends StatefulWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> tenantConfig;

  const SpaDetailPage({
    Key? key,
    required this.service,
    required this.tenantConfig,
  }) : super(key: key);

  @override
  _SpaDetailPageState createState() => _SpaDetailPageState();
}

class _SpaDetailPageState extends State<SpaDetailPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Futuro para carregar os dados de disponibilidade
  late Future<List<dynamic>> _availabilityFuture;
  List<dynamic> _availabilityData = [];

  @override
  void initState() {
    super.initState();
    _availabilityFuture = _loadAvailabilityData();
  }

  // Função para carregar o JSON de disponibilidade
  Future<List<dynamic>> _loadAvailabilityData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/tenant_assets/hotels/hotel_1/spa_availability.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> availabilityList = data['spaAvailability'] ?? [];

      // Encontra a disponibilidade do serviço de SPA com base no slug
      final spaAvailability = availabilityList.firstWhere(
        (item) => item['slug'] == widget.service['slug'],
        orElse: () => null,
      );

      if (spaAvailability != null && spaAvailability['availableDates'] != null) {
        _availabilityData = List<dynamic>.from(spaAvailability['availableDates']);
        return _availabilityData;
      }
      return [];
    } catch (e) {
      print('Erro ao carregar dados de disponibilidade do SPA: $e');
      return [];
    }
  }

  void _requestService(BuildContext pageContext) {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = Color(int.parse(widget.tenantConfig['colorPalette']['primary'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color cardBackgroundColor = Color(int.parse(widget.tenantConfig['colorPalette']['cardBackground'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color bodyTextColor = Color(int.parse(widget.tenantConfig['typography']['bodyText']['color'].substring(1, 7), radix: 16) + 0xFF000000);

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter modalSetState) {
            final formattedSelectedDate = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;
            final List<String> timesForSelectedDate = formattedSelectedDate != null
                ? _availabilityData
                    .firstWhere(
                      (item) => item['date'] == formattedSelectedDate,
                      orElse: () => {},
                    )['availableTimes']?.cast<String>() ?? []
                : [];

            return Container(
              height: MediaQuery.of(modalContext).size.height * 0.9,
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Agendar ${widget.service['name']}',
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<List<dynamic>>(
                            future: _availabilityFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return const Center(child: Text('Erro ao carregar os horários.'));
                              } else {
                                return TableCalendar(
                                  locale: 'pt_BR',
                                  focusedDay: _focusedDay,
                                  firstDay: DateTime.now(),
                                  lastDay: DateTime.now().add(const Duration(days: 30)),
                                  calendarFormat: _calendarFormat,
                                  enabledDayPredicate: (day) {
                                    final formattedDay = DateFormat('yyyy-MM-dd').format(day);
                                    return _availabilityData.any((item) => item['date'] == formattedDay);
                                  },
                                  selectedDayPredicate: (day) {
                                    return isSameDay(_selectedDate, day);
                                  },
                                  onDaySelected: (selectedDay, focusedDay) {
                                    modalSetState(() {
                                      final formattedDay = DateFormat('yyyy-MM-dd').format(selectedDay);
                                      if (_availabilityData.any((item) => item['date'] == formattedDay)) {
                                        _selectedDate = selectedDay;
                                        _focusedDay = focusedDay;
                                        _selectedTime = null;
                                      }
                                    });
                                  },
                                  onFormatChanged: (format) {
                                    modalSetState(() {
                                      _calendarFormat = format;
                                    });
                                  },
                                  calendarStyle: CalendarStyle(
                                    outsideDaysVisible: false,
                                    selectedDecoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    todayDecoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    disabledTextStyle: GoogleFonts.getFont(fontFamily, color: Colors.grey.withValues(alpha: 0.5)),
                                    markersMaxCount: 1,
                                    markerDecoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: GoogleFonts.getFont(
                                      fontFamily,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: bodyTextColor,
                                    ),
                                  ),
                                  daysOfWeekStyle: DaysOfWeekStyle(
                                    weekdayStyle: GoogleFonts.getFont(fontFamily, fontWeight: FontWeight.bold),
                                    weekendStyle: GoogleFonts.getFont(fontFamily, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_selectedDate != null) ...[
                            if (timesForSelectedDate.isNotEmpty) ...[
                              Text(
                                'Horários disponíveis para ${DateFormat('dd/MM').format(_selectedDate!)}:',
                                style: GoogleFonts.getFont(fontFamily, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                children: timesForSelectedDate.map((time) {
                                  final isSelected = _selectedTime == time;
                                  return ChoiceChip(
                                    label: Text(time),
                                    selected: isSelected,
                                    onSelected: (bool selected) {
                                      modalSetState(() {
                                        _selectedTime = selected ? time : null;
                                      });
                                    },
                                    selectedColor: primaryColor.withValues(alpha: 0.5),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: (_selectedDate != null && _selectedTime != null) ? () {
                                  Navigator.of(dialogContext).pop();
                                  ScaffoldMessenger.of(pageContext).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Agendamento para ${widget.service['name']} em ${DateFormat('dd/MM/yyyy').format(_selectedDate!)} às $_selectedTime enviado com sucesso!',
                                        style: GoogleFonts.getFont(fontFamily, color: Colors.white),
                                      ),
                                      backgroundColor: primaryColor,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  ).closed.then((_) {
                                    Navigator.of(pageContext).pop();
                                  });
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (_selectedDate != null && _selectedTime != null) ? primaryColor : Colors.grey,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: Text('Confirmar Agendamento', style: GoogleFonts.getFont(fontFamily, color: Colors.white)),
                              ),
                            ] else ...[
                              Text(
                                'Nenhum horário disponível para esta data.',
                                style: GoogleFonts.getFont(fontFamily, fontSize: 16, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ] else ...[
                            Text(
                              'Selecione uma data para ver os horários disponíveis.',
                              style: GoogleFonts.getFont(fontFamily, fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = Color(int.parse(widget.tenantConfig['colorPalette']['primary'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color backgroundColor = Color(int.parse(widget.tenantConfig['colorPalette']['background'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color bodyTextColor = Color(int.parse(widget.tenantConfig['typography']['bodyText']['color'].substring(1, 7), radix: 16) + 0xFF000000);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Image.asset(
                      widget.service['imageUrl'] ?? 'assets/tenant_assets/hotels/hotel_1/images/spa/massagem_terapeutica.png',
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: Icon(Icons.spa, size: 80, color: Colors.grey[500]),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: primaryColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.service['name'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${widget.service['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: bodyTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.service['description'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: bodyTextColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _requestService(context),
                      icon: const Icon(Icons.calendar_today, size: 24),
                      label: Text('Agendar Serviço', style: GoogleFonts.getFont(fontFamily, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}