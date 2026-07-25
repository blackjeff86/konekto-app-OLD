enum MessageSender { guest, staff }

/// Mensagem de chat entre hóspede e recepção, por estadia — todo mundo
/// hospedado no mesmo quarto compartilha a mesma conversa.
class StayMessage {
  final String id;
  final MessageSender senderType;
  final String? guestFirstName;
  final String body;
  final DateTime createdAt;

  const StayMessage({
    required this.id,
    required this.senderType,
    this.guestFirstName,
    required this.body,
    required this.createdAt,
  });

  factory StayMessage.fromJson(Map<String, dynamic> json) {
    final guest = json['guest'] as Map<String, dynamic>?;
    return StayMessage(
      id: json['id'] as String,
      senderType: json['senderType'] == 'staff' ? MessageSender.staff : MessageSender.guest,
      guestFirstName: guest?['firstName'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
