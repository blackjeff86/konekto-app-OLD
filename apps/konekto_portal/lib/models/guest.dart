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
/// contato, estadia) + código de acesso pessoal, criado pela recepção ou
/// gerente. `accessCode` já vem prefixado com uma tag do hotel (ex:
/// "HOTEL1-8F3A2B1C") — só exibição/auditoria, a API garante a unicidade.
class Guest {
  final String id;
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
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String roomNumber;
  final String? wifiPassword;
  final String accessCode;
  final GuestStatus status;
  final DateTime createdAt;

  const Guest({
    required this.id,
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
    required this.checkInDate,
    required this.checkOutDate,
    required this.roomNumber,
    this.wifiPassword,
    required this.accessCode,
    required this.status,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] as String,
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
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      roomNumber: json['roomNumber'] as String,
      wifiPassword: json['wifiPassword'] as String?,
      accessCode: json['accessCode'] as String,
      status: GuestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Dados do formulário de cadastro — sem `id`/`accessCode`/`status`, que só
/// existem depois que a API cria o hóspede.
class NewGuestInput {
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
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String roomNumber;
  final String? wifiPassword;

  const NewGuestInput({
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
    required this.checkInDate,
    required this.checkOutDate,
    required this.roomNumber,
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
      if (whatsappCountryCode != null) 'whatsappCountryCode': whatsappCountryCode,
      if (whatsappNumber != null) 'whatsappNumber': whatsappNumber,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'country': country,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'roomNumber': roomNumber,
      if (wifiPassword != null) 'wifiPassword': wifiPassword,
    };
  }
}
