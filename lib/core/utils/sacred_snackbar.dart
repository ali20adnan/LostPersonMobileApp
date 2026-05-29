import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/themes/app_colors.dart';
import '../../app/themes/app_motion.dart';

/// Themed Get.snackbar wrapper with a gold accent bar, calm decelerated
/// entrance, and color presets for success/error/info.
class SacredSnackbar {
  SacredSnackbar._();

  static void show({
    required String title,
    required String message,
    Color? accent,
    Color? background,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    final accentColor = accent ?? AppColors.accent;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          background ?? AppColors.surfaceDark.withValues(alpha: 0.95),
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: duration,
      animationDuration: AppMotion.emphasized,
      forwardAnimationCurve: AppMotion.emphasizedCurve,
      reverseAnimationCurve: AppMotion.accelerate,
      leftBarIndicatorColor: accentColor,
      icon: icon == null ? null : Icon(icon, color: accentColor, size: 22),
      boxShadows: AppColors.cardShadow,
    );
  }

  static void success(String title, String message) =>
      show(title: title, message: message, accent: AppColors.success);

  static void error(String title, String message) =>
      show(title: title, message: message, accent: AppColors.error);

  static void info(String title, String message) =>
      show(title: title, message: message, accent: AppColors.info);
}
