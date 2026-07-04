import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> tenantConfig;

  const EventDetailPage({
    Key? key,
    required this.event,
    required this.tenantConfig,
  }) : super(key: key);

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  late Future<List<String>> _availableTimesFuture;
  List<String> _availableTimes = [];
  final TenantRepository _repository = createTenantRepository();

  @override
  void initState() {
    super.initState();
    _availableTimesFuture = _loadEventAvailability();
  }

  Future<List<String>> _loadEventAvailability() async {
    try {
      final String tenantId = widget.tenantConfig['id'] ?? 'hotel_1';
      final Map<String, dynamic> data = await _repository.getEventAvailability(tenantId);
      final List<dynamic> availabilityData = data['eventAvailability'] ?? [];

      final eventAvailability = availabilityData.firstWhere(
        (item) => item['slug'] == widget.event['slug'],
        orElse: () => null,
      );

      if (eventAvailability != null) {
        _availableTimes = List<String>.from(eventAvailability['availableTimes'] ?? []);
        return _availableTimes;
      }
      return [];
    } catch (e) {
      print('Erro ao carregar dados de disponibilidade do evento: $e');
      return [];
    }
  }

  Color hexToColor(String hexCode) {
    if (hexCode.isEmpty) {
      return Colors.transparent;
    }
    return Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
  }

  void _requestEventParticipation(BuildContext pageContext) {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final Color cardBackgroundColor = hexToColor(widget.tenantConfig['colorPalette']['cardBackground']);
    final Color bodyTextColor = hexToColor(widget.tenantConfig['typography']['bodyText']['color']);
    final String buttonText = widget.event['buttonText'] ?? 'Solicitar Participação';

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter modalSetState) {
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
                      'Agendar Evento',
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
                          Text(
                            'Selecione a data:',
                            style: GoogleFonts.getFont(fontFamily, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TableCalendar(
                            locale: 'pt_BR',
                            focusedDay: _focusedDay,
                            firstDay: DateTime.now(),
                            lastDay: DateTime.now().add(const Duration(days: 30)),
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDate, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              modalSetState(() {
                                _selectedDate = selectedDay;
                                _focusedDay = focusedDay;
                                _selectedTime = null;
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
                          ),
                          const SizedBox(height: 24),
                          if (_selectedDate != null) ...[
                            Text(
                              'Selecione o horário:',
                              style: GoogleFonts.getFont(fontFamily, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              children: _availableTimes.map((time) {
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
                              onPressed: (_selectedDate != null && _selectedTime != null)
                                  ? () {
                                      Navigator.of(dialogContext).pop();
                                      final String eventTitle = widget.event['title'] ?? 'Evento';
                                      final String successMessage = 'Sua solicitação para o evento \'$eventTitle\' em ${DateFormat('dd/MM/yyyy').format(_selectedDate!)} às $_selectedTime foi enviada com sucesso!';

                                      ScaffoldMessenger.of(pageContext)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                successMessage,
                                                style: GoogleFonts.getFont(fontFamily, color: Colors.white),
                                              ),
                                              backgroundColor: primaryColor,
                                              duration: const Duration(seconds: 4),
                                            ),
                                          )
                                          .closed
                                          .then((SnackBarClosedReason reason) {
                                            Navigator.of(pageContext).pop();
                                          });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_selectedDate != null && _selectedTime != null) ? primaryColor : Colors.grey,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(buttonText, style: GoogleFonts.getFont(fontFamily, color: Colors.white)),
                            ),
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
  return FutureBuilder<List<String>>(
    future: _availableTimesFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      } else if (snapshot.hasError) {
        return Scaffold(body: Center(child: Text('Erro ao carregar os horários disponíveis.', style: GoogleFonts.getFont(widget.tenantConfig['typography']['fontFamily']))));
      }

      final String fontFamily = widget.tenantConfig['typography']?['fontFamily'] ?? 'Poppins';
      final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']?['primary'] ?? '#FF0000');
      final Color backgroundColor = hexToColor(widget.tenantConfig['colorPalette']?['background'] ?? '#FFFFFF');
      final Color bodyTextColor = hexToColor(widget.tenantConfig['typography']?['bodyText']?['color'] ?? '#000000');

      final String imageFileName = widget.event['imageFileName'] ?? '';
      final String tenantId = widget.tenantConfig['id'] ?? 'hotel_1';
      final String imagePath = 'assets/tenant_assets/hotels/$tenantId/images/eventos/$imageFileName';

      return Scaffold(
        backgroundColor: backgroundColor,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              leading: Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: Icon(Icons.event, size: 80, color: Colors.grey[500]),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event['title'] ?? '',
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: primaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.event['description'] ?? '',
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: bodyTextColor,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.event['location'] != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, color: primaryColor, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.event['location'],
                              style: GoogleFonts.getFont(
                                fontFamily,
                                color: bodyTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _requestEventParticipation(context),
                        icon: const Icon(Icons.calendar_today, size: 24, color: Colors.white),
                        label: Text('Solicitar Participação', style: GoogleFonts.getFont(fontFamily, fontSize: 16, color: Colors.white)),
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
            ),
          ],
        ),
      );
    },
  );
}
}