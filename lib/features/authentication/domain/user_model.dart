import 'dart:math' as math;

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? mobile;
  final bool mobileVerified;
  final String role;
  final String? department;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    this.mobileVerified = false,
    required this.role,
    this.department,
    this.isActive = true,
  });

  /// Extracts 1-2 character uppercase initials for badges and avatar circles.
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'OF';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return 'OF';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Officer').toString(),
      email: (json['email'] ?? '').toString(),
      mobile: json['mobile']?.toString(),
      mobileVerified: json['mobile_verified'] as bool? ?? json['mobileVerified'] as bool? ?? false,
      role: (json['role'] ?? 'OFFICER').toString(),
      department: json['department']?.toString(),
      isActive: json['isActive'] as bool? ?? (json['status'] == 'ACTIVE' || json['status'] == null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'mobile_verified': mobileVerified,
      'role': role,
      'department': department,
      'isActive': isActive,
    };
  }
}
