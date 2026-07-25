/// Empresa parceira cadastrada pelo hotel (ex: um estúdio de massagem
/// terceirizado) — vinculada item a item do catálogo em Configurações →
/// Serviços, não tem login/acesso próprio ao portal.
class Partner {
  final String id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? notes;

  const Partner({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.notes,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as String,
      name: json['name'] as String,
      contactName: json['contactName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// Dados do formulário de criação/edição de um parceiro.
class PartnerInput {
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? notes;

  const PartnerInput({
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contactName': contactName,
      'phone': phone,
      'email': email,
      'notes': notes,
    };
  }
}
