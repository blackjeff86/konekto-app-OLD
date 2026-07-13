import 'package:konekto_portal/models/stay.dart';

enum GuestStatus {
  active,
  revoked;

  static GuestStatus fromString(String value) {
    return GuestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw ArgumentError('Status de hóspede desconhecido: "$value"'),
    );
  }
}

enum DocumentType {
  cpf,
  passport,
  other;

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError('Tipo de documento desconhecido: "$value"'),
    );
  }

  String get label => switch (this) {
        DocumentType.cpf => 'CPF',
        DocumentType.passport => 'Passaporte',
        DocumentType.other => 'Outro',
      };
}

/// Hóspede individual de um hotel — cadastro completo (nome, documento,
/// contato) + código de acesso pessoal, sempre vinculado a uma `Stay` (o
/// quarto/estadia compartilhado com o resto da família). `accessCode` já
/// vem prefixado com uma tag do hotel (ex: "HOTEL1-8F3A2B1C") — só
/// exibição/auditoria, a API garante a unicidade.
///
/// `orders` só vem preenchido quando o JSON de origem é o endpoint de
/// DETALHE (`GET /api/hotels/:hotelId/guests/:guestId`) — na listagem
/// (`GET /api/hotels/:hotelId/guests`) vem vazio.
class Guest {
  final String id;
  final String stayId;
  final String firstName;
  final String lastName;
  final DocumentType documentType;
  final String documentNumber;
  final String phoneCountryCode;
  final String phoneNumber;
  final String? whatsappCountryCode;
  final String? whatsappNumber;
  final String? email;
  final String? address;
  final String country;
  final String? wifiPassword;
  final String accessCode;
  final GuestStatus status;
  final DateTime createdAt;
  final StaySummary stay;
  final List<GuestOrderSummary> orders;

  const Guest({
    required this.id,
    required this.stayId,
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.phoneCountryCode,
    required this.phoneNumber,
    this.whatsappCountryCode,
    this.whatsappNumber,
    this.email,
    this.address,
    required this.country,
    this.wifiPassword,
    required this.accessCode,
    required this.status,
    required this.createdAt,
    required this.stay,
    this.orders = const [],
  });

  String get fullName => '$firstName $lastName';
  String get roomNumber => stay.roomNumber;
  DateTime get checkInDate => stay.checkInDate;
  DateTime get checkOutDate => stay.checkOutDate;

  factory Guest.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>?;
    return Guest(
      id: json['id'] as String,
      stayId: json['stayId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      documentType: DocumentType.fromString(json['documentType'] as String),
      documentNumber: json['documentNumber'] as String,
      phoneCountryCode: json['phoneCountryCode'] as String,
      phoneNumber: json['phoneNumber'] as String,
      whatsappCountryCode: json['whatsappCountryCode'] as String?,
      whatsappNumber: json['whatsappNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String,
      wifiPassword: json['wifiPassword'] as String?,
      accessCode: json['accessCode'] as String,
      status: GuestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      stay: StaySummary.fromJson(json['stay'] as Map<String, dynamic>),
      orders: rawOrders == null
          ? const []
          : rawOrders.map((raw) => GuestOrderSummary.fromJson(raw as Map<String, dynamic>)).toList(),
    );
  }
}

/// Dados do formulário de cadastro — sem `id`/`accessCode`/`status`, que só
/// existem depois que a API cria o hóspede. `stayId` referencia a estadia
/// (quarto) já criada onde esse hóspede vai entrar.
class NewGuestInput {
  final String stayId;
  final String firstName;
  final String lastName;
  final DocumentType documentType;
  final String documentNumber;
  final String phoneCountryCode;
  final String phoneNumber;
  final String? whatsappCountryCode;
  final String? whatsappNumber;
  final String? email;
  final String? address;
  final String country;
  final String? wifiPassword;

  const NewGuestInput({
    required this.stayId,
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.phoneCountryCode,
    required this.phoneNumber,
    this.whatsappCountryCode,
    this.whatsappNumber,
    this.email,
    this.address,
    required this.country,
    this.wifiPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'stayId': stayId,
      'firstName': firstName,
      'lastName': lastName,
      'documentType': documentType.name,
      'documentNumber': documentNumber,
      'phoneCountryCode': phoneCountryCode,
      'phoneNumber': phoneNumber,
      if (whatsappCountryCode != null) 'whatsappCountryCode': whatsappCountryCode,
      if (whatsappNumber != null) 'whatsappNumber': whatsappNumber,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'country': country,
      if (wifiPassword != null) 'wifiPassword': wifiPassword,
    };
  }
}

/// Cadastro mais recente de uma pessoa encontrado pelo documento —
/// devolvido por `GET /api/hotels/:hotelId/guests/lookup`, usado pra
/// reaproveitar os dados de alguém que já se hospedou antes ao ocupar um
/// quarto, sem digitar tudo de novo.
class GuestLookupResult {
  final String firstName;
  final String lastName;
  final DocumentType documentType;
  final String documentNumber;
  final String phoneCountryCode;
  final String phoneNumber;
  final String? whatsappCountryCode;
  final String? whatsappNumber;
  final String? email;
  final String? address;
  final String country;

  const GuestLookupResult({
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.phoneCountryCode,
    required this.phoneNumber,
    this.whatsappCountryCode,
    this.whatsappNumber,
    this.email,
    this.address,
    required this.country,
  });

  factory GuestLookupResult.fromJson(Map<String, dynamic> json) {
    return GuestLookupResult(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      documentType: DocumentType.fromString(json['documentType'] as String),
      documentNumber: json['documentNumber'] as String,
      phoneCountryCode: json['phoneCountryCode'] as String,
      phoneNumber: json['phoneNumber'] as String,
      whatsappCountryCode: json['whatsappCountryCode'] as String?,
      whatsappNumber: json['whatsappNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String,
    );
  }
}

/// Dados do formulário de EDIÇÃO de um hóspede já existente — mesmos
/// campos pessoais de `NewGuestInput`, sem `stayId` (mudar de quarto é uma
/// operação diferente, fora de escopo). Diferente de `NewGuestInput`,
/// manda os campos opcionais mesmo quando `null` — é assim que o hóspede
/// consegue LIMPAR um campo (ex: apagar o e-mail) em vez de só preencher.
class GuestEditInput {
  final String firstName;
  final String lastName;
  final DocumentType documentType;
  final String documentNumber;
  final String phoneCountryCode;
  final String phoneNumber;
  final String? whatsappCountryCode;
  final String? whatsappNumber;
  final String? email;
  final String? address;
  final String country;
  final String? wifiPassword;

  const GuestEditInput({
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.phoneCountryCode,
    required this.phoneNumber,
    this.whatsappCountryCode,
    this.whatsappNumber,
    this.email,
    this.address,
    required this.country,
    this.wifiPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'documentType': documentType.name,
      'documentNumber': documentNumber,
      'phoneCountryCode': phoneCountryCode,
      'phoneNumber': phoneNumber,
      'whatsappCountryCode': whatsappCountryCode,
      'whatsappNumber': whatsappNumber,
      'email': email,
      'address': address,
      'country': country,
      'wifiPassword': wifiPassword,
    };
  }
}
