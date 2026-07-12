import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_portal/api_config.dart';
import 'package:konekto_portal/models/coupon.dart';

class CouponsRepository {
  final http.Client _client;

  CouponsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Coupon>> listCoupons({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/coupons'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar cupons (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => Coupon.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Coupon> createCoupon({required String hotelId, required String token, required CouponInput input}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/coupons'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode == 409) {
      throw StateError('Já existe um cupom com esse código.');
    }
    if (response.statusCode != 201) {
      throw StateError('Falha ao criar cupom (status ${response.statusCode}).');
    }
    return Coupon.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateCoupon({
    required String hotelId,
    required String couponId,
    required String token,
    required CouponInput input,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/coupons/$couponId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(input.toJson()),
    );
    if (response.statusCode == 409) {
      throw StateError('Já existe um cupom com esse código.');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar cupom (status ${response.statusCode}).');
    }
  }

  Future<void> setEnabled({
    required String hotelId,
    required String couponId,
    required String token,
    required bool enabled,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/coupons/$couponId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'enabled': enabled}),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao atualizar cupom (status ${response.statusCode}).');
    }
  }

  Future<void> deleteCoupon({required String hotelId, required String couponId, required String token}) async {
    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/api/hotels/$hotelId/coupons/$couponId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 409) {
      throw StateError('Esse cupom já foi usado em pedidos — desative-o em vez de remover.');
    }
    if (response.statusCode != 200) {
      throw StateError('Falha ao remover cupom (status ${response.statusCode}).');
    }
  }
}
