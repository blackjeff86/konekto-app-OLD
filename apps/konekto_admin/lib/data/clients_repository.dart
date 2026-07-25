import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:konekto_admin/api_config.dart';

class Subscription {
  final String planName;
  final double? monthlyAmount;
  final String status;
  final String paymentStatus;
  final String? notes;
  // Categoria White Label (essential/premium/enterprise) — controla
  // template/feature flag do app do hóspede, distinto de `planName` (texto
  // livre exibido no financeiro). Ver apps/konekto_api/lib/feature-flags.ts.
  final String plan;

  const Subscription({
    required this.planName,
    this.monthlyAmount,
    required this.status,
    required this.paymentStatus,
    this.notes,
    required this.plan,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      planName: json['planName'] as String,
      monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble(),
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      notes: json['notes'] as String?,
      plan: json['plan'] as String? ?? 'essential',
    );
  }
}

class IntegrationHealth {
  final bool configured;
  final bool enabled;
  final DateTime? lastInboundSyncAt;
  final DateTime? lastOutboundAt;
  final bool? lastOutboundOk;
  final String? lastOutboundError;

  const IntegrationHealth({
    required this.configured,
    required this.enabled,
    this.lastInboundSyncAt,
    this.lastOutboundAt,
    this.lastOutboundOk,
    this.lastOutboundError,
  });

  factory IntegrationHealth.fromJson(Map<String, dynamic> json) {
    return IntegrationHealth(
      configured: json['configured'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? false,
      lastInboundSyncAt: json['lastInboundSyncAt'] != null ? DateTime.tryParse(json['lastInboundSyncAt'] as String) : null,
      lastOutboundAt: json['lastOutboundAt'] != null ? DateTime.tryParse(json['lastOutboundAt'] as String) : null,
      lastOutboundOk: json['lastOutboundOk'] as bool?,
      lastOutboundError: json['lastOutboundError'] as String?,
    );
  }
}

class StaffMember {
  final String id;
  final String name;
  final String email;
  final String role;

  const StaffMember({required this.id, required this.name, required this.email, required this.role});

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}

/// Visão administrativa de um hotel cliente — espelha `HotelOverview` do
/// backend (`lib/platform-admin-hotel-shape.ts`).
class HotelOverview {
  final String hotelId;
  final String name;
  final String? address;
  final Subscription? subscription;
  // Flags que o plano já dá por padrão (somente leitura na UI de cortesia —
  // não faz sentido "desligar" o que o plano já inclui).
  final List<String> defaultFeatures;
  // Só as extras de cortesia (`Hotel.config.enabledFeatures`), nunca as do
  // plano — é exatamente o que `updateEnabledFeatures` espera de volta.
  final List<String> enabledFeatures;
  final int activeGuestCount;
  final IntegrationHealth integration;
  final int unreadSupportMessages;
  final List<StaffMember> staff;

  const HotelOverview({
    required this.hotelId,
    required this.name,
    required this.address,
    required this.subscription,
    this.defaultFeatures = const [],
    this.enabledFeatures = const [],
    required this.activeGuestCount,
    required this.integration,
    required this.unreadSupportMessages,
    this.staff = const [],
  });

  factory HotelOverview.fromJson(Map<String, dynamic> json) {
    return HotelOverview(
      hotelId: json['hotelId'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      subscription: json['subscription'] != null ? Subscription.fromJson(json['subscription'] as Map<String, dynamic>) : null,
      defaultFeatures: (json['defaultFeatures'] as List<dynamic>?)?.map((item) => item as String).toList() ?? const [],
      enabledFeatures: (json['enabledFeatures'] as List<dynamic>?)?.map((item) => item as String).toList() ?? const [],
      activeGuestCount: json['activeGuestCount'] as int? ?? 0,
      integration: IntegrationHealth.fromJson(json['integration'] as Map<String, dynamic>),
      unreadSupportMessages: json['unreadSupportMessages'] as int? ?? 0,
      staff: (json['staff'] as List<dynamic>?)
              ?.map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Resultado da criação de um hotel — a `temporaryPassword` só existe em
/// texto puro nesta resposta; depois disso só o hash fica salvo.
class CreateHotelResult {
  final String hotelId;
  final String gerenteName;
  final String gerenteEmail;
  final String temporaryPassword;

  const CreateHotelResult({
    required this.hotelId,
    required this.gerenteName,
    required this.gerenteEmail,
    required this.temporaryPassword,
  });

  factory CreateHotelResult.fromJson(Map<String, dynamic> json) {
    final gerente = json['gerente'] as Map<String, dynamic>;
    return CreateHotelResult(
      hotelId: json['hotelId'] as String,
      gerenteName: gerente['name'] as String,
      gerenteEmail: gerente['email'] as String,
      temporaryPassword: json['temporaryPassword'] as String,
    );
  }
}

class ClientsRepository {
  final http.Client _client;

  ClientsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<HotelOverview>> listHotels({required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/platform-admin/hotels'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar clientes (status ${response.statusCode}).');
    }
    final raw = jsonDecode(response.body) as List<dynamic>;
    return raw.map((item) => HotelOverview.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<HotelOverview> getHotel({required String hotelId, required String token}) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl/api/platform-admin/hotels/$hotelId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao carregar o cliente (status ${response.statusCode}).');
    }
    return HotelOverview.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<CreateHotelResult> createHotel({
    required String token,
    required String name,
    required String plan,
    required String gerenteName,
    required String gerenteEmail,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/api/platform-admin/hotels'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'plan': plan,
        'gerente': {'name': gerenteName, 'email': gerenteEmail},
      }),
    );
    if (response.statusCode == 409) {
      throw StateError('Já existe uma conta com este e-mail de gerente.');
    }
    if (response.statusCode != 201) {
      throw StateError('Falha ao criar o hotel (status ${response.statusCode}).');
    }
    return CreateHotelResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateSubscription({
    required String hotelId,
    required String token,
    required String planName,
    double? monthlyAmount,
    required String status,
    required String paymentStatus,
    String? notes,
    required String plan,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/platform-admin/hotels/$hotelId/subscription'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'planName': planName,
        'monthlyAmount': monthlyAmount,
        'status': status,
        'paymentStatus': paymentStatus,
        'notes': notes,
        'plan': plan,
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao salvar o plano (status ${response.statusCode}).');
    }
  }

  /// Substitui a lista INTEIRA de flags de cortesia (nunca as do plano —
  /// ver `HotelOverview.enabledFeatures`). Só o time Konekto usa isso; não
  /// existe equivalente no portal do hotel.
  Future<void> updateEnabledFeatures({
    required String hotelId,
    required String token,
    required List<String> enabledFeatures,
  }) async {
    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/api/platform-admin/hotels/$hotelId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'enabledFeatures': enabledFeatures}),
    );
    if (response.statusCode != 200) {
      throw StateError('Falha ao salvar os recursos de cortesia (status ${response.statusCode}).');
    }
  }
}
