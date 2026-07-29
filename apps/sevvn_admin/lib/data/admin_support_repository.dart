import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sevvn_admin/api_config.dart';

class SupportThreadSummary {
  final String hotelId;
  final String hotelName;
  final DateTime lastMessageAt;
  final String lastMessageBody;
  final String lastMessageSenderType;
  final int unreadByPlatform;

  const SupportThreadSummary({
    required this.hotelId,
    required this.hotelName,
    required this.lastMessageAt,
    required this.lastMessageBody,
    required this.lastMessageSenderType,
    required this.unreadByPlatform,
  });

  factory SupportThreadSummary.fromJson(Map<String, dynamic> json) {
    return SupportThreadSummary(
      hotelId: json['hotelId'] as String,
      hotelName: json['hotelName'] as String,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      lastMessageBody: json['lastMessageBody'] as String,
      lastMessageSenderType: json['lastMessageSenderType'] as String,
      unreadByPlatform: json['unreadByPlatform'] as int? ?? 0,
    );
  }
}

class SupportMessage {
  final String id;
  final String senderType; // 'hotel' ou 'platform'
  final String body;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.senderType,
    required this.body,
    required this.createdAt,
  });

  bool get isFromHotel => senderType == 'hotel';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String,
      senderType: json['senderType'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminSupportRepository {
  final http.Client _client;

  AdminSupportRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<SupportThreadSummary>> listThreads({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/platform-admin/support-messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar as conversas (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => SupportThreadSummary.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<SupportMessage>> listMessages({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/platform-admin/hotels/$hotelId/support-messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar a conversa (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => SupportMessage.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage({required String hotelId, required String token, required String message}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/platform-admin/hotels/$hotelId/support-messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode != 201) {
      throw StateError('Falha ao enviar a resposta (status ${response.statusCode}).');
    }
  }

  Future<void> markThreadRead({required String hotelId, required String token}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/platform-admin/hotels/$hotelId/support-messages/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao marcar como lida (status ${response.statusCode}).');
    }
  }
}

