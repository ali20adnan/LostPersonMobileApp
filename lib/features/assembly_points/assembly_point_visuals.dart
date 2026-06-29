import 'package:flutter/material.dart';

/// Shared visual helpers for assembly points (color parsing + palette).

/// Default marker color when a point has no color set (brand blue).
const Color kAssemblyPointDefaultColor = Color(0xFF2563EB);

/// Color shown for inactive (disabled) points — matches the web's gray.
const Color kAssemblyPointInactiveColor = Color(0xFF9CA3AF);

/// The selectable color palette offered when creating/editing a point.
/// Mirrors the web's 10-color quick palette EXACTLY (LostPersonsWeb
/// assembly-points page `COLOR_PALETTE`).
const List<String> kAssemblyPointPalette = [
  '#2563EB', // أزرق
  '#DC2626', // أحمر
  '#16A34A', // أخضر
  '#F59E0B', // برتقالي
  '#9333EA', // بنفسجي
  '#0891B2', // سماوي
  '#DB2777', // وردي
  '#65A30D', // ليموني
  '#EA580C', // برتقالي محروق
  '#475569', // رمادي مزرق
];

/// Parse a hex color string like `#2563eb` / `2563eb` / `#ff2563eb` into a
/// [Color]. Returns [kAssemblyPointDefaultColor] for null/invalid input.
Color assemblyPointColor(String? hex) {
  if (hex == null) return kAssemblyPointDefaultColor;
  var value = hex.trim().replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value'; // add opaque alpha
  if (value.length != 8) return kAssemblyPointDefaultColor;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return kAssemblyPointDefaultColor;
  return Color(parsed);
}
