import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto/api_config.dart';
import 'package:konekto/models/coupon.dart';

/// Cupons/promoções disponíveis pro hóspede autenticado — usado pra
/// deixar ele escolher da lista ao fazer um pedido (não digita código).
class CouponsRepository {
  final http.Client _client;

  CouponsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Coupon>> listAvailable({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/coupons'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar cupons (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Coupon.fromJson(item as Map<String, dynamic>)).toList();
  }
}
