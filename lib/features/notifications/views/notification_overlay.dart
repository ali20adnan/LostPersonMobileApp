import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/notifications_page_controller.dart';
import '../widgets/notification_item.dart';
import 'notifications_page.dart';

/// Floating notification bell button + glassmorphic dropdown overlay
class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isOpen = controller.isOverlayOpen.value;
      // Flutter clips hit-tests to the parent's bounds even when the visual
      // bleeds out via Clip.none. Without the SizedBox below, taps inside
      // the dropdown fall through to NotificationDismissBarrier and close
      // the overlay instead of reaching the InkWell of each item.
      return SizedBox(
        width: isOpen
            ? MediaQuery.of(context).size.width * 0.9
            : 44,
        height: isOpen ? 500 : 44,
        // Non-directional alignment + explicit Positioned for the bell:
        // under RTL the default AlignmentDirectional.topStart resolves to
        // top-RIGHT, so when the SizedBox grew on open the bell jumped
        // rightward with the new corner. Pinning to (0, 0) keeps the
        // visual position identical between collapsed and expanded states.
        child: Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: [
            // ── Bell Button (fixed at the SizedBox's top-left) ─────
            Positioned(
              top: 0,
              left: 0,
              child: GestureDetector(
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
                      color: isDark
                          ? AppColors.glassBorderDark
                          : AppColors.glassBorder,
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
                            PhosphorIcons.bell(),
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
            ),

            // ── Dropdown Overlay ─────────────────────────────
            if (controller.isOverlayOpen.value)
              Positioned(
                top: 52,
                left: 0,
                child: _NotificationDropdown(controller: controller)
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(
                        begin: -0.1,
                        end: 0,
                        duration: 250.ms,
                        curve: Curves.easeOutCubic),
              ),
          ],
        ),
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
                        // Ensure the page controller is registered (the binding
                        // chain via named routes was not firing reliably from
                        // here), then push the page directly.
                        if (!Get.isRegistered<NotificationsPageController>()) {
                          Get.put(NotificationsPageController());
                        }
                        Get.to(() => const NotificationsPage());
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

              // Unified notification list (alerts + persisted + unread hints)
              // Use ConstrainedBox + non-shrinkWrap ListView so the list
              // actually scrolls when content exceeds the dropdown height.
              // (Flexible inside MainAxisSize.min + shrinkWrap was breaking
              // gesture-driven scrolling.)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.entries.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (controller.entries.isEmpty) {
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

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    physics: const ClampingScrollPhysics(),
                    itemCount: controller.entries.length,
                    itemBuilder: (context, index) {
                      final entry = controller.entries[index];
                      return NotificationItem(
                        entry: entry,
                        onTap: () => _handleEntryTap(entry, controller),
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

/// Route a tap on a unified [NotificationEntry] to the right action.
/// Always closes the overlay and pushes a screen so the user gets feedback
/// that their tap was registered.
void _handleEntryTap(NotificationEntry entry, NotificationsController ctrl) {
  // Mark alert as read locally before routing.
  if (entry.type == 'alert' && entry.id != null) {
    ctrl.markAsRead(entry.id!);
  }

  ctrl.isOverlayOpen.value = false;

  // Persisted notifications have a real detail screen — open it directly.
  if (entry.type == 'missingPerson' || entry.type == 'centerReport') {
    if (!Get.isRegistered<NotificationsPageController>()) {
      Get.put(NotificationsPageController());
    }
    final pageCtrl = Get.find<NotificationsPageController>();
    if (entry.type == 'missingPerson') {
      pageCtrl.handleMissingPersonTap(entry);
    } else {
      pageCtrl.handleCenterReportTap(entry);
    }
    return;
  }

  // Alerts / message hints / report hints → fall back to the full
  // notifications page so the user can see the entry in context.
  if (!Get.isRegistered<NotificationsPageController>()) {
    Get.put(NotificationsPageController());
  }
  Get.to(() => const NotificationsPage());
}
