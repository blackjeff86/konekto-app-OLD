/// Sessão de um admin da PLATAFORMA (equipe do Konekto) — sem `hotelId`,
/// diferente da `StaffSession` do portal: essa conta enxerga todos os
/// hotéis clientes.
class AdminSession {
  final String id;
  final String name;
  final String email;

  const AdminSession({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
