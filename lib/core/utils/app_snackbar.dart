import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/themes/app_colors.dart';
import '../../app/themes/app_motion.dart';

/// Centralized snackbars for the whole app.
///
/// Three styles, by intent:
/// * [glass]      — frosted-glass toast; the default for every in-app message.
/// * [missingNew] — "new missing person" notification, solid theme color.
/// * [emergency]  — emergency-report notification, fiery red.
///
/// [glass] intentionally keeps the legacy `Get.snackbar(title, message, ...)`
/// shape so old call sites can swap in unchanged. Per-call color/margin/radius
/// args are accepted but ignored, keeping the glass look uniform everywhere.
class AppSnackbar {
  AppSnackbar._();

  /// Fiery red — emergency-report notifications.
  static const Color emergencyRed = Color(0xFFFF3B30);

  /// Brand navy, lightened so it reads clearly on dark backgrounds —
  /// new-missing-person notifications.
  static const Color missingBlue = Color(0xFF3A5199);

  /// Frosted-glass toast. Default style for every generic message.
  static void glass(
    String title,
    String message, {
    SnackPosition? snackPosition,
    Color? backgroundColor, // ignored — kept for call-site compatibility
    Color? colorText, // ignored — glass text is always white
    EdgeInsets? margin, // ignored — uniform glass margin
    double? borderRadius, // ignored — uniform glass radius
    Duration? duration,
    Widget? icon,
    void Function(GetSnackBar)? onTap,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: snackPosition ?? SnackPosition.TOP,
      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.45),
      colorText: Colors.white,
      barBlur: 18,
      borderColor: AppColors.glassBorder,
      borderWidth: 1,
      borderRadius: 18,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      duration: duration ?? const Duration(seconds: 3),
      animationDuration: AppMotion.emphasized,
      forwardAnimationCurve: AppMotion.emphasizedCurve,
      reverseAnimationCurve: AppMotion.accelerate,
      icon: icon,
      onTap: onTap,
      boxShadows: AppColors.cardShadow,
    );
  }

  /// Solid, opaque banner shared by the two notification types.
  static void _solid({
    required String title,
    required String message,
    required Color color,
    Widget? icon,
    Duration duration = const Duration(seconds: 5),
    void Function(GetSnackBar)? onTap,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: duration,
      animationDuration: AppMotion.emphasized,
      forwardAnimationCurve: AppMotion.emphasizedCurve,
      reverseAnimationCurve: AppMotion.accelerate,
      icon: icon,
      onTap: onTap,
      boxShadows: AppColors.elevatedShadow,
    );
  }

  /// "New missing person" notification — solid, clearly-visible theme color.
  static void missingNew({
    required String title,
    required String message,
    Widget? icon,
    Duration duration = const Duration(seconds: 5),
    void Function(GetSnackBar)? onTap,
  }) =>
      _solid(
        title: title,
        message: message,
        color: missingBlue,
        icon: icon,
        duration: duration,
        onTap: onTap,
      );

  /// Emergency-report notification — fiery red.
  static void emergency({
    required String title,
    required String message,
    Widget? icon,
    Duration duration = const Duration(seconds: 5),
    void Function(GetSnackBar)? onTap,
  }) =>
      _solid(
        title: title,
        message: message,
        color: emergencyRed,
        icon: icon,
        duration: duration,
        onTap: onTap,
      );
}
