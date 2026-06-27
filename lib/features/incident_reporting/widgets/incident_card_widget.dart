import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/shared/tap_scale.dart';
import '../../../data/models/incident_model.dart';
import '../../../core/constants/incident_constants.dart';

/// Widget displaying report information in a card format
class IncidentCardWidget extends StatelessWidget {
  final Report incident;
  final VoidCallback onTap;

  const IncidentCardWidget({
    super.key,
    required this.incident,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = ReportType.fromString(incident.type);
    final severity = ReportSeverity.fromString(incident.severity ?? 'medium');
    final status = ReportStatus.fromApiString(incident.status);

    final muted = isDark
        ? AppColors.textOnDarkSecondary
        : AppColors.textSecondary;
    final hasDescription = (incident.description ?? '').trim().isNotEmpty;
    final hasLocation = (incident.addressLine ?? '').trim().isNotEmpty;

    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: soft icon chip + title/type + status pill ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: severity.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(type.icon, color: severity.color, size: 22),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.displayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(3),
                      Text(
                        type.displayNameAr,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                _SoftPill(
                  label: status.displayNameAr,
                  color: status.color,
                  bold: true,
                ),
              ],
            ),

            // ── Description ──
            if (hasDescription) ...[
              const Gap(12),
              Text(
                incident.description!.trim(),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textOnDark.withValues(alpha: 0.72)
                      : AppColors.textPrimary.withValues(alpha: 0.72),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Gap(14),

            // ── Meta row: location + severity + time + directions ──
            Row(
              children: [
                Icon(PhosphorIcons.clock(), size: 14, color: muted),
                const Gap(4),
                Text(
                  _formatTimestamp(incident.createdAt),
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                if (hasLocation) ...[
                  const Gap(12),
                  Icon(PhosphorIcons.mapPin(), size: 14, color: muted),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      incident.addressLine!.trim(),
                      style: TextStyle(fontSize: 12, color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                const Gap(8),
                _SoftPill(
                  label: severity.displayNameAr,
                  color: severity.color,
                ),
                if (incident.latitude != null &&
                    incident.longitude != null) ...[
                  const Gap(6),
                  GestureDetector(
                    onTap: () => openMapsDirections(
                      lat: incident.latitude,
                      lng: incident.longitude,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        PhosphorIcons.navigationArrow(),
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format timestamp to relative time
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('yyyy-MM-dd').format(timestamp);
    }
  }
}

/// Small soft-tinted pill used for status & severity labels — matches the
/// website's Badge style (soft background, colored text, compact).
class _SoftPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool bold;

  const _SoftPill({
    required this.label,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // On the navy dark cards, Material status colors (grey/deepOrange/…) read
    // too dim, so lift the label toward white and strengthen the soft tint.
    final textColor = isDark ? Color.lerp(color, Colors.white, 0.45)! : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.24 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
