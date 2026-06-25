import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_translator_app/core/utils/icon_direction.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/shared/tap_scale.dart';
import '../../../data/models/missing_person_report_model.dart';
import '../services/pending_found_requests_service.dart';

/// Reusable card for displaying a missing / found person
class MissingPersonCard extends StatelessWidget {
  final MissingPersonReport person;
  final bool isFound;
  final VoidCallback? onMarkFound;
  final VoidCallback? onTap;

  const MissingPersonCard({
    super.key,
    required this.person,
    required this.isFound,
    this.onMarkFound,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isFound ? AppColors.teal : AppColors.primary;
    final urgentColor = isFound ? AppColors.teal : AppColors.accent;

    final muted = isDark
        ? AppColors.textOnDarkSecondary
        : AppColors.textSecondary;
    final hasDescription = (person.description ?? '').trim().isNotEmpty;
    final hasLocation = (person.lastSeenAddress ?? '').trim().isNotEmpty;

    return TapScale(
      onTap: onTap ?? () => Get.toNamed(
        AppRoutes.missingPersonDetail,
        arguments: {'reportId': person.id},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: isDark ? null : AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName ?? 'غير معروف',
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(PhosphorIcons.cake(), size: 13, color: muted),
                          const SizedBox(width: 3),
                          Text(
                            '${person.age ?? '?'} سنة',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                          const SizedBox(width: 8),
                          Icon(PhosphorIcons.user(), size: 13, color: muted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              person.gender ?? '',
                              style: TextStyle(fontSize: 12, color: muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SoftPill(
                  label: _relativeTime(person.createdAt),
                  color: urgentColor,
                ),
              ],
            ),

            if (hasDescription) ...[
              const SizedBox(height: 12),
              Text(
                person.description!.trim(),
                style: TextStyle(fontSize: 13, height: 1.4, color: muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(PhosphorIcons.mapPin(), size: 14, color: muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hasLocation ? person.lastSeenAddress!.trim() : 'غير محدد',
                    style: TextStyle(fontSize: 12, color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (person.coordinates != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => openMapsDirections(
                      lat: person.coordinates!['latitude'],
                      lng: person.coordinates!['longitude'],
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

            if (isFound) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.checkCircle().ltr,
                        size: 14, color: AppColors.teal),
                    const SizedBox(width: 6),
                    Text(
                      'تم العثور عليه ${_relativeTime(person.updatedAt)}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!isFound) ...[
              const SizedBox(height: 12),
                      // Mark as Found button — shows "قيد المراجعة" (disabled)
                      // while a volunteer's request awaits CENTER/ADMIN approval.
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() {
                          final isPending = Get.find<PendingFoundRequestsService>()
                              .isPending(person.id);
                          return Container(
                            decoration: BoxDecoration(
                              gradient:
                                  isPending ? null : AppColors.successGradient,
                              color: isPending
                                  ? (isDark
                                      ? AppColors.cardDark
                                      : AppColors.surfaceSunken)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: isPending
                                  ? Border.all(
                                      color: AppColors.teal.withValues(alpha: 0.4))
                                  : null,
                              boxShadow: isPending
                                  ? null
                                  : [
                                      BoxShadow(
                                        color:
                                            AppColors.teal.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isPending ? null : onMarkFound,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Icon(
                                          isPending
                                              ? Icons.hourglass_top
                                              : Icons.check_circle,
                                          size: 16,
                                          color: isPending
                                              ? AppColors.teal
                                              : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isPending ? 'قيد المراجعة' : 'تم العثور',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isPending
                                              ? AppColors.teal
                                              : Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            );
  }

  Widget _buildAvatar(Color color) {
    final photoUrl = person.primaryPhotoUrl;
    return Hero(
      tag: 'mp-photo-${person.id}',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl != null
              ? Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initialsWidget(color),
                )
              : _initialsWidget(color),
        ),
      ),
    );
  }

  Widget _initialsWidget(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.08)],
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(person.fullName ?? ''),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0];
    }
    return '?';
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${time.day}/${time.month}/${time.year}';
  }
}

/// Small soft-tinted pill — matches the website's compact Badge style.
class _SoftPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SoftPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
