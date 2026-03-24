import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/notifications_page_controller.dart';

/// Single notification item in the unified timeline
class NotificationItem extends StatelessWidget {
  final NotificationEntry entry;
  final VoidCallback? onTap;

  const NotificationItem({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _entryColor(entry);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: isDark ? null : AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_entryIcon(entry), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(entry.createdAt),
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _entryIcon(NotificationEntry entry) {
    switch (entry.type) {
      case 'alert':
        switch (entry.alertType) {
          case 'sighting':
            return PhosphorIcons.eye();
          case 'tip':
            return PhosphorIcons.lightbulb();
          case 'found':
            return PhosphorIcons.checkCircle();
          case 'information':
            return PhosphorIcons.info();
          default:
            return PhosphorIcons.bell();
        }
      case 'message':
        return PhosphorIcons.chatCircle();
      case 'report':
        return PhosphorIcons.fileText();
      default:
        return PhosphorIcons.bell();
    }
  }

  Color _entryColor(NotificationEntry entry) {
    switch (entry.type) {
      case 'alert':
        switch (entry.alertType) {
          case 'sighting':
            return AppColors.info;
          case 'tip':
            return AppColors.warning;
          case 'found':
            return AppColors.success;
          default:
            return AppColors.primary;
        }
      case 'message':
        return AppColors.secondary;
      case 'report':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return '${dt.day}/${dt.month}';
  }
}
