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

/// Hóspede individual de um hotel — nome + quarto + código de acesso
/// pessoal, criado pela recepção/gerente.
class Guest {
  final String id;
  final String name;
  final String roomNumber;
  final String accessCode;
  final GuestStatus status;
  final DateTime createdAt;

  const Guest({
    required this.id,
    required this.name,
    required this.roomNumber,
    required this.accessCode,
    required this.status,
    required this.createdAt,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] as String,
      name: json['name'] as String,
      roomNumber: json['roomNumber'] as String,
      accessCode: json['accessCode'] as String,
      status: GuestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
