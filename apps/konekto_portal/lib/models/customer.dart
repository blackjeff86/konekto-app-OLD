import 'package:konekto_portal/models/guest.dart' show DocumentType;

/// Uma estadia passada ou atual dentro do histórico de um cliente —
/// diferente de `Stay` (usado na aba Quartos), este já vem achatado com o
/// valor gasto naquela estadia especificamente.
class CustomerStayEntry {
  final String stayId;
  final String roomNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String status;
  final int nights;
  final double spent;

  const CustomerStayEntry({
    required this.stayId,
    required this.roomNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.nights,
    required this.spent,
  });

  factory CustomerStayEntry.fromJson(Map<String, dynamic> json) {
    return CustomerStayEntry(
      stayId: json['stayId'] as String,
      roomNumber: json['roomNumber'] as String,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      status: json['status'] as String,
      nights: json['nights'] as int,
      spent: (json['spent'] as num).toDouble(),
    );
  }
}

/// Uma pessoa que já se hospedou no hotel, agregando todas as vezes que
/// ela apareceu (mesmo `documentNumber`) — não existe uma tabela de
/// "cliente" própria, isso é montado pela API a partir dos `Guest` de
/// cada estadia.
class Customer {
  final DocumentType documentType;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String? email;
  final String phoneCountryCode;
  final String phoneNumber;
  final String? whatsappCountryCode;
  final String? whatsappNumber;
  final String country;
  final int visitsCount;
  final double totalSpent;
  final DateTime firstVisit;
  final DateTime lastVisit;
  final List<CustomerStayEntry> stays;

  const Customer({
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phoneCountryCode,
    required this.phoneNumber,
    this.whatsappCountryCode,
    this.whatsappNumber,
    required this.country,
    required this.visitsCount,
    required this.totalSpent,
    required this.firstVisit,
    required this.lastVisit,
    this.stays = const [],
  });

  String get fullName => '$firstName $lastName';

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawStays = json['stays'] as List<dynamic>? ?? const [];
    return Customer(
      documentType: DocumentType.fromString(json['documentType'] as String),
      documentNumber: json['documentNumber'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String?,
      phoneCountryCode: json['phoneCountryCode'] as String,
      phoneNumber: json['phoneNumber'] as String,
      whatsappCountryCode: json['whatsappCountryCode'] as String?,
      whatsappNumber: json['whatsappNumber'] as String?,
      country: json['country'] as String,
      visitsCount: json['visitsCount'] as int,
      totalSpent: (json['totalSpent'] as num).toDouble(),
      firstVisit: DateTime.parse(json['firstVisit'] as String),
      lastVisit: DateTime.parse(json['lastVisit'] as String),
      stays: rawStays.map((raw) => CustomerStayEntry.fromJson(raw as Map<String, dynamic>)).toList(),
    );
  }
}
