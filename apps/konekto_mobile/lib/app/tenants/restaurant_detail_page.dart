import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:konekto/data/tenant_repository.dart';
import 'package:konekto/data/tenant_repository_provider.dart';

class RestaurantDetailPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final Map<String, dynamic> tenantConfig;

  const RestaurantDetailPage({
    Key? key,
    required this.restaurant,
    required this.tenantConfig,
  }) : super(key: key);

  @override
  _RestaurantDetailPageState createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<String> _availableTimes = [];
  final TenantRepository _repository = createTenantRepository();

  @override
  void initState() {
    super.initState();
    _loadAvailabilityData();
  }

  // Função para carregar o JSON de disponibilidade
  Future<void> _loadAvailabilityData() async {
    try {
      final String hotelId = widget.tenantConfig['id'] ?? 'hotel_1';
      final Map<String, dynamic> data = await _repository.getRestaurantAvailability(hotelId);
      final List<dynamic> availabilityData = data['restaurantAvailability'] ?? [];

      final restaurantAvailability = availabilityData.firstWhere(
        (item) => item['slug'] == widget.restaurant['slug'],
        orElse: () => null,
      );

      if (restaurantAvailability != null && mounted) {
        setState(() {
          _availableTimes = List<String>.from(restaurantAvailability['availableTimes'] ?? []);
        });
      }
    } catch (e) {
      print('Erro ao carregar dados de disponibilidade do restaurante: $e');
    }
  }

  void _requestBooking(BuildContext pageContext) {
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
                      'Agendar Reserva',
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
                                      
                                      ScaffoldMessenger.of(pageContext)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Reserva para o restaurante ${widget.restaurant['name']} em ${DateFormat('dd/MM/yyyy').format(_selectedDate!)} às $_selectedTime enviada com sucesso!',
                                                style: GoogleFonts.getFont(fontFamily, color: Colors.white),
                                              ),
                                              backgroundColor: primaryColor,
                                              duration: const Duration(seconds: 4),
                                            ),
                                          )
                                          .closed
                                          .then((SnackBarClosedReason reason) {
                                        // Navega de volta para a tela anterior quando o SnackBar sumir
                                        Navigator.of(pageContext).pop();
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_selectedDate != null && _selectedTime != null) ? primaryColor : Colors.grey,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text('Confirmar Reserva', style: GoogleFonts.getFont(fontFamily, color: Colors.white)),
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
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = Color(int.parse(widget.tenantConfig['colorPalette']['primary'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color backgroundColor = Color(int.parse(widget.tenantConfig['colorPalette']['background'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color bodyTextColor = Color(int.parse(widget.tenantConfig['typography']['bodyText']['color'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color cardBackgroundColor = Color(int.parse(widget.tenantConfig['colorPalette']['cardBackground'].substring(1, 7), radix: 16) + 0xFF000000);

    final List<dynamic>? menuItems = widget.restaurant['menuItems'];

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
                widget.restaurant['imageUrl'] ?? 'assets/tenant_assets/hotels/hotel_1/images/restaurants/le_mare.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: Icon(Icons.restaurant, size: 80, color: Colors.grey[500]),
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
                    widget.restaurant['name'] ?? '',
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.restaurant['description'] ?? '',
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
                      onPressed: () => _requestBooking(context),
                      icon: const Icon(Icons.restaurant, size: 24),
                      label: Text('Reservar Mesa', style: GoogleFonts.getFont(fontFamily, fontSize: 16)),
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
                  const SizedBox(height: 24),
                  if (menuItems != null && menuItems.isNotEmpty) ...[
                    Text(
                      'Cardápio',
                      style: GoogleFonts.getFont(
                        fontFamily,
                        color: primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(color: primaryColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entradas',
                            style: GoogleFonts.getFont(
                              fontFamily,
                              color: bodyTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...menuItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      item['imageUrl'] ?? 'assets/tenant_assets/hotels/hotel_1/images/food/placeholder.jpg',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey[500]),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? '',
                                          style: GoogleFonts.getFont(
                                            fontFamily,
                                            color: bodyTextColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['description'] ?? '',
                                          style: GoogleFonts.getFont(
                                            fontFamily,
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'R\$ ${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                                          style: GoogleFonts.getFont(
                                            fontFamily,
                                            color: primaryColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}