import 'package:flutter/material.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  /// Generates a consistent color for this user's avatar
  Color get avatarColor {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
    ];
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
