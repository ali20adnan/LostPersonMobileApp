import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/notifications_controller.dart';
import '../../../data/models/alert_model.dart';

/// Floating notification bell button + glassmorphic dropdown overlay
class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Bell Button ──────────────────────────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.toggleOverlay();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.glassBorderDark : AppColors.glassBorder,
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        controller.isOverlayOpen.value
                            ? PhosphorIcons.bell()
                            : PhosphorIcons.bell(),
                        color: AppColors.primary,
                        size: 22,
                      ),
                      // Unread badge
                      if (controller.unreadCount.value > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              controller.unreadCount.value > 99
                                  ? '99+'
                                  : '${controller.unreadCount.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Dropdown Overlay ─────────────────────────────
          if (controller.isOverlayOpen.value)
            Positioned(
              top: 52,
              left: 0,
              child: _NotificationDropdown(controller: controller)
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: -0.1, end: 0, duration: 250.ms, curve: Curves.easeOutCubic),
            ),
        ],
      );
    });
  }
}

/// Full-screen tap barrier that closes the overlay when tapping outside
class NotificationDismissBarrier extends StatelessWidget {
  const NotificationDismissBarrier({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationsController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<NotificationsController>();
    return Obx(() {
      if (!controller.isOverlayOpen.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: GestureDetector(
          onTap: () => controller.isOverlayOpen.value = false,
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.transparent),
        ),
      );
    });
  }
}

class _NotificationDropdown extends StatelessWidget {
  final NotificationsController controller;

  const _NotificationDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: const BoxConstraints(maxHeight: 420),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorder,
            ),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.bell(), size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'الإشعارات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Obx(() => controller.unreadCount.value > 0
                        ? TextButton.icon(
                            onPressed: controller.markAllAsRead,
                            icon: Icon(PhosphorIcons.checkCircle(), size: 14),
                            label: const Text('قراءة الكل',
                                style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        : const SizedBox.shrink()),
                    TextButton.icon(
                      onPressed: () {
                        controller.isOverlayOpen.value = false;
                        Get.toNamed(AppRoutes.notifications);
                      },
                      icon: Icon(PhosphorIcons.arrowLeft(), size: 14),
                      label: const Text('عرض الكل',
                          style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),

              // Alert list
              Flexible(
                child: Obx(() {
                  if (controller.isLoading.value && controller.alerts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (controller.alerts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft.withValues(
                                  alpha: isDark ? 0.2 : 1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIcons.bellRinging(),
                              size: 32,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد إشعارات',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: controller.alerts.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    ),
                    itemBuilder: (context, index) {
                      if (index == controller.alerts.length - 1) {
                        controller.loadMore();
                      }
                      return _AlertTile(
                        alert: controller.alerts[index],
                        onTap: () =>
                            controller.markAsRead(controller.alerts[index].id),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single alert tile with modern design
class _AlertTile extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;

  const _AlertTile({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _typeColor(alert.type, theme).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _typeIcon(alert.type),
                size: 18,
                color: _typeColor(alert.type, theme),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor(alert.type, theme)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          alert.typeDisplayAr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _typeColor(alert.type, theme),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(alert.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (alert.report?.personName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      alert.report!.personName!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
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
  }

  Color _typeColor(String type, ThemeData theme) {
    switch (type) {
      case 'sighting':
        return AppColors.info;
      case 'tip':
        return AppColors.warning;
      case 'found':
        return AppColors.success;
      case 'information':
        return AppColors.primary;
      default:
        return AppColors.secondary;
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
