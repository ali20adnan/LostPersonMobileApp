import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_translator_app/core/utils/icon_direction.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/services/auth_service.dart';
import '../../../core/constants/api_constants.dart';
import '../controllers/notifications_page_controller.dart';

/// Single notification tile — styled to match the conversations screen.
class NotificationItem extends StatelessWidget {
  final NotificationEntry entry;
  final VoidCallback? onTap;

  const NotificationItem({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _entryColor(entry);
    final hasUnread = !entry.isRead;
    final cardColor = isDark ? AppColors.cardDark : AppColors.card;

    // Show the account owner's profile photo on every notification, with the
    // notification type as a small colored badge on the corner.
    final accountUser = Get.isRegistered<AuthService>()
        ? Get.find<AuthService>().currentUser.value
        : null;
    final avatarUrl = ApiConstants.resolveAvatarUrl(accountUser?.avatarUrl);
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
        ),
        boxShadow: hasUnread
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Account-owner avatar with a colored notification-type badge.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasAvatar
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _avatarFallback(accountUser?.fullName, color),
                            )
                          : _avatarFallback(accountUser?.fullName, color),
                    ),
                    // Type badge
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                        child: Icon(
                          _entryIcon(entry),
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              hasUnread ? FontWeight.bold : FontWeight.w600,
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: hasUnread
                              ? (isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time + unread indicator
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(entry.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: hasUnread
                            ? AppColors.primary
                            : AppColors.textLight,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (hasUnread) ...[
                      const Gap(6),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Fallback shown when the account has no avatar — initials on a tinted
  /// gradient, or a person glyph when the name is unavailable.
  Widget _avatarFallback(String? name, Color color) {
    final initials = _initials(name ?? '');
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : Icon(PhosphorIcons.user(), color: Colors.white, size: 22),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    if (parts.isNotEmpty) return parts[0][0];
    return '';
  }

  IconData _entryIcon(NotificationEntry entry) {
    switch (entry.type) {
      case 'alert':
        switch (entry.alertType) {
          case 'found':
            return PhosphorIcons.checkCircle().ltr;
          default:
            return PhosphorIcons.bell();
        }
      case 'message':
        return PhosphorIcons.chatCircle();
      case 'report':
        return PhosphorIcons.fileText();
      case 'missingPerson':
        return PhosphorIcons.userCircle();
      case 'centerReport':
        return PhosphorIcons.warningOctagon();
      default:
        return PhosphorIcons.bell();
    }
  }

  Color _entryColor(NotificationEntry entry) {
    switch (entry.type) {
      case 'alert':
        switch (entry.alertType) {
          case 'found':
            return AppColors.success;
          default:
            return AppColors.primary;
        }
      case 'message':
        return AppColors.secondary;
      case 'report':
        return AppColors.accent;
      case 'missingPerson':
        return AppColors.error;
      case 'centerReport':
        return entry.centerReportType == 'emergency'
            ? AppColors.error
            : AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return '${diff.inMinutes} د';
    if (diff.inDays < 1) return '${diff.inHours} س';
    if (diff.inDays < 7) return '${diff.inDays} ي';
    return '${dt.day}/${dt.month}';
  }
}
