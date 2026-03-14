import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';

/// A modern pill-shaped badge for showing status, category, or info.
/// Supports icons, colors, and compact/normal sizing.
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool compact;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.compact = false,
    this.fontSize,
  });

  // ── Factory constructors for common statuses ─────────────────
  factory StatusBadge.success(String label, {IconData? icon}) => StatusBadge(
        label: label,
        icon: icon,
        backgroundColor: AppColors.successLight,
        textColor: const Color(0xFF166534),
        iconColor: AppColors.success,
      );

  factory StatusBadge.error(String label, {IconData? icon}) => StatusBadge(
        label: label,
        icon: icon,
        backgroundColor: AppColors.errorLight,
        textColor: const Color(0xFF991B1B),
        iconColor: AppColors.error,
      );

  factory StatusBadge.warning(String label, {IconData? icon}) => StatusBadge(
        label: label,
        icon: icon,
        backgroundColor: AppColors.warningLight,
        textColor: const Color(0xFF92400E),
        iconColor: AppColors.warning,
      );

  factory StatusBadge.info(String label, {IconData? icon}) => StatusBadge(
        label: label,
        icon: icon,
        backgroundColor: AppColors.infoLight,
        textColor: const Color(0xFF1E40AF),
        iconColor: AppColors.info,
      );

  factory StatusBadge.primary(String label, {IconData? icon}) => StatusBadge(
        label: label,
        icon: icon,
        backgroundColor: AppColors.primarySoft,
        textColor: AppColors.primaryDark,
        iconColor: AppColors.primary,
      );

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primarySoft;
    final fgColor = textColor ?? AppColors.primaryDark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 12 : 14,
              color: iconColor ?? fgColor,
            ),
            SizedBox(width: compact ? 3 : 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize ?? (compact ? 10 : 12),
              fontWeight: FontWeight.w600,
              color: fgColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
