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

/// Reusable card for displaying a missing / found person.
///
/// Visual language mirrors the login screen: a single signature accent
/// (gold for active reports, teal for found people), soft rounded surfaces,
/// a glowing avatar ring, and a gradient call-to-action with a colored glow.
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

    // One signature accent per card — gold while still missing (echoing the
    // login's sacred-gold), teal once the person has been found.
    final accent = isFound ? AppColors.teal : AppColors.accent;
    final accentGradient =
        isFound ? AppColors.successGradient : AppColors.accentGradient;

    final muted =
        isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary;
    final title = isDark ? AppColors.textOnDark : AppColors.textPrimary;

    final hasDescription = (person.description ?? '').trim().isNotEmpty;
    final hasLocation = (person.lastSeenAddress ?? '').trim().isNotEmpty;

    return TapScale(
      onTap: onTap ??
          () => Get.toNamed(
                AppRoutes.missingPersonDetail,
                arguments: {'reportId': person.id},
              ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: isDark ? null : AppColors.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Signature accent edge ──────────────────────────
              Container(width: 5, decoration: BoxDecoration(gradient: accentGradient)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header: avatar + identity + time ───────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatar(accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person.fullName ?? 'غير معروف',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    height: 1.2,
                                    color: title,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _MetaChip(
                                      icon: PhosphorIcons.cake(),
                                      label: '${person.age ?? '?'} سنة',
                                      muted: muted,
                                    ),
                                    if ((person.gender ?? '').trim().isNotEmpty)
                                      _MetaChip(
                                        icon: PhosphorIcons.user(),
                                        label: person.gender!.trim(),
                                        muted: muted,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SoftPill(
                            label: _relativeTime(person.createdAt),
                            color: accent,
                          ),
                        ],
                      ),

                      if (hasDescription) ...[
                        const SizedBox(height: 12),
                        Text(
                          person.description!.trim(),
                          style:
                              TextStyle(fontSize: 13, height: 1.45, color: muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),

                      // ── Location chip ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceSunkenDark
                                    : AppColors.surfaceSunken,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(PhosphorIcons.mapPin(),
                                      size: 14, color: accent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      hasLocation
                                          ? person.lastSeenAddress!.trim()
                                          : 'موقع غير محدد',
                                      style:
                                          TextStyle(fontSize: 12, color: muted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (person.coordinates != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => openMapsDirections(
                                lat: person.coordinates!['latitude'],
                                lng: person.coordinates!['longitude'],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  PhosphorIcons.navigationArrow(),
                                  size: 15,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (isFound) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.18)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.checkCircle().ltr,
                                  size: 15, color: AppColors.teal),
                              const SizedBox(width: 6),
                              Text(
                                'تم العثور عليه ${_relativeTime(person.updatedAt)}',
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (!isFound) ...[
                        const SizedBox(height: 14),
                        _buildMarkFoundButton(isDark),
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

  /// Primary action — styled like the login button: full-width gradient,
  /// rounded corners, and a soft colored glow. Falls back to a calm
  /// "under review" pill while a volunteer's request awaits approval.
  Widget _buildMarkFoundButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        final isPending =
            Get.find<PendingFoundRequestsService>().isPending(person.id);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: isPending ? null : AppColors.successGradient,
            color: isPending
                ? (isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken)
                : null,
            borderRadius: BorderRadius.circular(14),
            border: isPending
                ? Border.all(color: AppColors.teal.withValues(alpha: 0.4))
                : null,
            boxShadow: isPending
                ? null
                : [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isPending ? null : onMarkFound,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Icon(
                        isPending ? Icons.hourglass_top : Icons.check_circle,
                        size: 17,
                        color: isPending ? AppColors.teal : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isPending ? 'قيد المراجعة' : 'تم العثور عليه',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        leadingDistribution: TextLeadingDistribution.even,
                        color: isPending ? AppColors.teal : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAvatar(Color color) {
    final photoUrl = person.primaryPhotoUrl;
    return Hero(
      tag: 'mp-photo-${person.id}',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.20),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
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
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(person.fullName ?? ''),
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
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

/// Compact icon + label chip for identity metadata (age, gender).
/// Uniform soft surface keeps the header tidy and consistent.
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color muted;

  const _MetaChip({required this.icon, required this.label, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: muted),
          ),
        ],
      ),
    );
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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
