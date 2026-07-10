/// Aviso da recepção pro quarto do hóspede — só leitura, sem resposta.
class StayNotice {
  final String id;
  final String message;
  final DateTime createdAt;

  const StayNotice({required this.id, required this.message, required this.createdAt});

  factory StayNotice.fromJson(Map<String, dynamic> json) {
    return StayNotice(
      id: json['id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
