import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Palette (Medium Navy) ────────────────────────────
  static const primary = Color(0xFF2C3E6B); // Medium Navy
  static const primaryDark = Color(0xFF1B2A4A);
  static const primaryLight = Color(0xFF5C7ABA);
  static const primarySoft = Color(0xFFE8EAF6);

  // ── Accent Palette (Gold - Dome & Minarets Inspired) ─────────
  static const accent = Color(0xFFC49B00); // Sacred Gold
  static const accentDark = Color(0xFFA17E00);
  static const accentLight = Color(0xFFFFD54F);
  static const accentSoft = Color(0xFFFFF8E1);

  // ── Secondary Palette (Steel Blue) ───────────────────────────
  static const secondary = Color(0xFF546E7A); // Steel Blue
  static const secondaryDark = Color(0xFF37474F);
  static const secondaryLight = Color(0xFF90A4AE);

  // ── Teal / Success Palette ───────────────────────────────────
  static const teal = Color(0xFF26A69A); // Warm Teal
  static const tealDark = Color(0xFF00897B);
  static const tealLight = Color(0xFF80CBC4);

  // ── Background & Surface ─────────────────────────────────────
  static const background = Color(0xFFF5F5F0); // Ivory
  static const backgroundDark = Color(0xFF0A1628); // Deep Blue-Black
  static const surface = Color(0xFFFFFDF7); // Warm White
  static const surfaceDark = Color(0xFF132238); // Dark Navy
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const surfaceElevatedDark = Color(0xFF1A3050);
  static const surfaceSunken = Color(0xFFECEBE4); // Warm Sunken
  static const surfaceSunkenDark = Color(0xFF0D1B2E);

  // ── Card Colors ──────────────────────────────────────────────
  static const card = Color(0xFFFFFDF7);
  static const cardDark = Color(0xFF1A2D47);
  static const cardBorder = Color(0xFFE8E5D8);
  static const cardBorderDark = Color(0xFF243B55);

  // ── Text Colors ──────────────────────────────────────────────
  static const textPrimary = Color(0xFF1B2631);
  static const textSecondary = Color(0xFF5D6D7E);
  static const textLight = Color(0xFF95A5A6);
  static const textOnPrimary = Colors.white;
  static const textOnDark = Color(0xFFF5F5F0);
  static const textOnDarkSecondary = Color(0xFF95A5A6);
  static const textSecondaryDark = Color(0xFFB0BEC5);

  // ── Status Colors ────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);

  // ── Connection Status ────────────────────────────────────────
  static const connected = Color(0xFF22C55E);
  static const disconnected = Color(0xFFEF4444);
  static const connecting = Color(0xFFF59E0B);

  // ── Divider & Border ─────────────────────────────────────────
  static const divider = Color(0xFFE0DDD0);
  static const dividerDark = Color(0xFF243B55);
  static const border = Color(0xFFD5D0C0);
  static const borderDark = Color(0xFF2C4A6E);

  // ── Record Button ────────────────────────────────────────────
  static const recordIdle = Color(0xFFD1D5DB);
  static const recordActive = Color(0xFFC49B00); // Gold when recording
  static const recordProcessing = Color(0xFF2C3E6B);
  static const recordPulse = Color(0x30C49B00);

  // ── Glassmorphism ────────────────────────────────────────────
  static const glassWhite = Color(0x80FFFFFF);
  static const glassDark = Color(0x40000000);
  static const glassBlur = 20.0;
  static const glassBorder = Color(0x30FFFFFF);
  static const glassBorderDark = Color(0x20FFFFFF);

  // ── Shimmer ──────────────────────────────────────────────────
  static const shimmerBase = Color(0xFFE0DDD0);
  static const shimmerHighlight = Color(0xFFF5F3EA);
  static const shimmerBaseDark = Color(0xFF243B55);
  static const shimmerHighlightDark = Color(0xFF2C4A6E);

  // ── Overlay ──────────────────────────────────────────────────
  static const overlay = Color(0x80000000);
  static const overlayLight = Color(0x40000000);

  // ── Gradients ────────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF1B2A4A), Color(0xFF2C3E6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFC49B00), Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF132238)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1B2A4A), Color(0xFF3A5199)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warmGradient = LinearGradient(
    colors: [Color(0xFFC49B00), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surfaceGradient = LinearGradient(
    colors: [Color(0xFFF5F5F0), Color(0xFFE8EAF6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Sacred gradient — deep navy to navy
  static const sacredGradient = LinearGradient(
    colors: [Color(0xFF0D1B3E), Color(0xFF2C3E6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ──────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF2C3E6B).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF2C3E6B).withValues(alpha: 0.15),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: const Color(0xFF2C3E6B).withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get goldShadow => [
        BoxShadow(
          color: const Color(0xFFC49B00).withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get bottomNavShadow => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.1),
          blurRadius: 30,
          offset: const Offset(0, -5),
        ),
      ];
}
