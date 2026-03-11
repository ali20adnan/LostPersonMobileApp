import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/notifications_controller.dart';
import '../../../data/models/alert_model.dart';

/// Floating notification bell button + dropdown overlay
class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();
    final theme = Theme.of(context);

    return Obx(() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Bell button with scale animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: controller.unreadCount.value > 0 ? 1.0 : 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(22),
              color: theme.colorScheme.surface,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.toggleOverlay();
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          controller.isOverlayOpen.value
                              ? Icons.notifications
                              : Icons.notifications_outlined,
                          key: ValueKey(controller.isOverlayOpen.value),
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      // Unread badge
                      if (controller.unreadCount.value > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              controller.unreadCount.value > 99
                                  ? '99+'
                                  : '${controller.unreadCount.value}',
                              style: TextStyle(
                                color: theme.colorScheme.onError,
                                fontSize: 10,
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

          // Dropdown overlay with animation
          if (controller.isOverlayOpen.value)
            Positioned(
              top: 52,
              left: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, -8 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _NotificationDropdown(controller: controller),
              ),
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

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'الإشعارات',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Obx(() => controller.unreadCount.value > 0
                      ? TextButton.icon(
                          onPressed: controller.markAllAsRead,
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text('قراءة الكل',
                              style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
            const Divider(height: 1),

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
                        Icon(Icons.notifications_off_outlined,
                            size: 40, color: theme.colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد إشعارات',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: controller.alerts.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, indent: 16, endIndent: 16,
                          color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                  itemBuilder: (context, index) {
                    // Load more when reaching end
                    if (index == controller.alerts.length - 1) {
                      controller.loadMore();
                    }
                    return _AlertTile(
                      alert: controller.alerts[index],
                      onTap: () => controller.markAsRead(
                          controller.alerts[index].id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single alert tile
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _typeColor(alert.type, theme).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
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
                            fontWeight: FontWeight.bold,
                            color: _typeColor(alert.type, theme),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(alert.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
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
                        color: theme.colorScheme.primary,
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
        return Icons.visibility;
      case 'tip':
        return Icons.lightbulb_outline;
      case 'found':
        return Icons.check_circle_outline;
      case 'information':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type, ThemeData theme) {
    switch (type) {
      case 'sighting':
        return Colors.blue;
      case 'tip':
        return Colors.orange;
      case 'found':
        return Colors.green;
      case 'information':
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
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
