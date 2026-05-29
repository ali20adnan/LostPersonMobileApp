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

    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left severity accent bar with gradient fade
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        severity.color,
                        severity.color.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Card content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: icon + title + status badge
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    severity.color,
                                    severity.color.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: severity.color.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                type.icon,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const Gap(10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    incident.displayTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.textOnDark
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Gap(2),
                                  Text(
                                    type.displayNameAr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textOnDarkSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: status.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: status.color.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                status.displayNameAr,
                                style: TextStyle(
                                  color: status.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.divider,
                        indent: 14,
                        endIndent: 14,
                      ),

                      // Body: description + location + severity + time
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Description
                            Text(
                              incident.description ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textOnDark.withValues(alpha: 0.75)
                                    : AppColors.textPrimary.withValues(alpha: 0.75),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(10),

                            // Location + severity row
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.mapPin(),
                                  size: 14,
                                  color: isDark
                                      ? AppColors.textOnDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                                const Gap(4),
                                Expanded(
                                  child: Text(
                                    incident.addressLine ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textOnDarkSecondary
                                          : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: severity.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    severity.displayNameAr,
                                    style: TextStyle(
                                      color: severity.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (incident.latitude != null &&
                                    incident.longitude != null) ...[
                                  const Gap(6),
                                  GestureDetector(
                                    onTap: () => openMapsDirections(
                                      lat: incident.latitude,
                                      lng: incident.longitude,
                                    ),
                                    child: Icon(
                                      PhosphorIcons.navigationArrow(),
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const Gap(8),

                            // Footer: time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      PhosphorIcons.clock(),
                                      size: 13,
                                      color: isDark
                                          ? AppColors.textOnDarkSecondary
                                          : AppColors.textLight,
                                    ),
                                    const Gap(4),
                                    Text(
                                      _formatTimestamp(incident.createdAt),
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textOnDarkSecondary
                                            : AppColors.textLight,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
