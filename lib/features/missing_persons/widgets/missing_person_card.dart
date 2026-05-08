import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../data/models/missing_person_report_model.dart';

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

    return GestureDetector(
      onTap: onTap ?? () => Get.toNamed(
        AppRoutes.missingPersonDetail,
        arguments: {'reportId': person.id},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: isDark ? null : AppColors.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Right accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [urgentColor, urgentColor.withValues(alpha: 0.4)],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(PhosphorIcons.cake(), size: 13, color: AppColors.textLight),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${person.age ?? '?'} سنة',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(PhosphorIcons.user(), size: 13, color: AppColors.textLight),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      person.gender ?? '',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: urgentColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _relativeTime(person.createdAt),
                            style: TextStyle(fontSize: 11, color: urgentColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(PhosphorIcons.fileText(), size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            person.description ?? '',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            person.lastSeenAddress ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                            ),
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
                            child: Icon(
                              PhosphorIcons.navigationArrow(),
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (isFound) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(PhosphorIcons.checkCircle(), size: 14, color: AppColors.teal),
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
                    ],

                    if (!isFound) ...[
                      const SizedBox(height: 10),
                      // Mark as Found button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.successGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onMarkFound,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Icon(Icons.check_circle, size: 16, color: Colors.white),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'تم العثور',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    final photoUrl = person.primaryPhotoUrl;
    return Container(
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
