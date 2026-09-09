import 'dart:math' as math;

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? department;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
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
      role: (json['role'] ?? 'OFFICER').toString(),
      department: json['department']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'isActive': isActive,
    };
  }
}
