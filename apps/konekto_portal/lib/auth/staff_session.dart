import 'package:konekto_portal/auth/staff_role.dart';

class StaffSession {
  final String uid;
  final String hotelId;
  final StaffRole role;
  final String name;
  final String email;

  const StaffSession({
    required this.uid,
    required this.hotelId,
    required this.role,
    required this.name,
    required this.email,
  });

  factory StaffSession.fromJson(Map<String, dynamic> json) {
    return StaffSession(
      uid: json['id'] as String,
      hotelId: json['hotelId'] as String,
      role: StaffRole.fromString(json['role'] as String),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
