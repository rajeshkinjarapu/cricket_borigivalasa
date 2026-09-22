import 'dart:convert';
import 'package:flutter/material.dart';

/// Returns a robust [ImageProvider] for any photo URL, supporting both
/// standard HTTP/HTTPS URLs and base64 encoded strings / data URIs.
ImageProvider? getAppAvatarProvider(String? photoUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final trimmed = photoUrl.trim();
  try {
    if (trimmed.startsWith('data:image') || !trimmed.startsWith('http')) {
      final base64String = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
      return MemoryImage(base64Decode(base64String));
    }
    return NetworkImage(trimmed);
  } catch (_) {
    return null;
  }
}

/// Builds a circular or squircle avatar fallback with user initials.
Widget buildAvatarFallback({
  required String name,
  double size = 44,
  double fontSize = 18,
  bool isSquircle = true,
  double borderRadius = 14,
  Color primaryColor = const Color(0xFF1E3A8A),
  Color secondaryColor = const Color(0xFF3B82F6),
}) {
  final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: isSquircle ? BorderRadius.circular(borderRadius) : null,
      shape: isSquircle ? BoxShape.rectangle : BoxShape.circle,
      gradient: LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    ),
  );
}
