import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/services/unread_count_service.dart';
import '../controllers/home_controller.dart';
import '../../notifications/views/notification_overlay.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../messaging/controllers/conversations_controller.dart';
import '../../messaging/views/messaging_overlay.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        Scaffold(
          // Transparent so the app-wide SacredBackground (mounted in main.dart)
          // shows through beneath all four tabs.
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Stack(
            children: [
              // Main content with a directional shared-axis slide between tabs:
              // moving to a higher-index tab slides one way, lower the other,
              // which reads as physically moving across the tab bar.
              Obx(() => PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 280),
                    reverse: !controller.goingForward,
                    transitionBuilder: (child, primary, secondary) {
                      return SharedAxisTransition(
                        animation: primary,
                        secondaryAnimation: secondary,
                        transitionType: SharedAxisTransitionType.horizontal,
                        fillColor: Colors.transparent,
                        child: child,
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(controller.currentIndex.value),
                      child: controller.pages[controller.currentIndex.value],
                    ),
                  )),

              // Tap barrier to close notification overlay (hidden on profile)
              Obx(() => controller.currentIndex.value != 3
                  ? const NotificationDismissBarrier()
                  : const SizedBox.shrink()),

              // Floating notification bell at top-left (hidden on profile).
              // White-glass variant everywhere EXCEPT the light-theme translator
              // tab (index 0), where the button uses the dark-theme navy fill so
              // it reads as a solid blue chip. Dark theme stays white-glass.
              Obx(() => controller.currentIndex.value != 3
                  ? Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 12,
                      child: NotificationOverlay(
                        // Solid style on the light-background map (0) and on
                        // the light-theme translator (1); white-glass elsewhere.
                        onDark: !(controller.currentIndex.value == 0 ||
                            (controller.currentIndex.value == 1 && !isDark)),
                      ),
                    )
                  : const SizedBox.shrink()),

              // Floating messaging icon at top-right (hidden on profile)
              Obx(() => controller.currentIndex.value != 3
                  ? Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 12,
                      child: MessagingOverlay(
                        // Solid style on the light-background map (0) and on
                        // the light-theme translator (1); white-glass elsewhere.
                        onDark: !(controller.currentIndex.value == 0 ||
                            (controller.currentIndex.value == 1 && !isDark)),
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),

          // ── Floating Bottom Navigation Bar ──────────────────────
          bottomNavigationBar: Obx(
            () => Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppColors.accent.withValues(alpha: 0.3)
                            : AppColors.accent.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: AppColors.bottomNavShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: PhosphorIcons.mapTrifold(),
                          activeIcon:
                              PhosphorIcons.mapTrifold(PhosphorIconsStyle.fill),
                          label: 'الخريطة',
                          isSelected: controller.currentIndex.value == 0,
                          onTap: () => _onTabTap(0),
                        ),
                        _NavItem(
                          icon: PhosphorIcons.translate(),
                          activeIcon: PhosphorIcons.translate(),
                          label: 'الترجمة',
                          isSelected: controller.currentIndex.value == 1,
                          onTap: () => _onTabTap(1),
                        ),
                        // Center FAB
                        _CenterFab(
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _closeOverlays();
                            _showReportTypeSheet(context);
                          },
                        ),
                        _NavItem(
                          icon: PhosphorIcons.fileText(),
                          activeIcon: PhosphorIcons.fileText(),
                          label: 'البلاغات',
                          isSelected: controller.currentIndex.value == 2,
                          badgeCount: _getAlertsBadge() + _getReportsBadge(),
                          onTap: () => _onTabTap(2),
                        ),
                        _NavItem(
                          icon: PhosphorIcons.user(),
                          activeIcon: PhosphorIcons.user(),
                          label: 'حسابي',
                          isSelected: controller.currentIndex.value == 3,
                          onTap: () => _onTabTap(3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().slideY(
                  begin: 1,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
        ),

        // Messaging dismiss barrier
        const MessagingDismissBarrier(),

        // Instagram-style slide-in messaging panel
        const MessagingSlidePanel(),
      ],
    );
  }

  void _onTabTap(int index) {
    HapticFeedback.lightImpact();
    _closeOverlays();
    controller.changePage(index);
  }

  void _closeOverlays() {
    if (Get.isRegistered<NotificationsController>()) {
      final nc = Get.find<NotificationsController>();
      if (nc.isOverlayOpen.value) nc.isOverlayOpen.value = false;
    }
    if (Get.isRegistered<ConversationsController>()) {
      final mc = Get.find<ConversationsController>();
      if (mc.isMessagingPanelOpen.value) mc.isMessagingPanelOpen.value = false;
    }
  }

  int _getAlertsBadge() {
    if (!Get.isRegistered<UnreadCountService>()) return 0;
    return Get.find<UnreadCountService>().alertsUnread.value;
  }

  int _getReportsBadge() {
    if (!Get.isRegistered<UnreadCountService>()) return 0;
    return Get.find<UnreadCountService>().reportsUnread.value;
  }

  void _showReportTypeSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'نوع الإبلاغ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const Gap(16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(PhosphorIcons.warningCircle(), color: Colors.white),
              ),
              title: Text('بلاغ عادي',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  )),
              subtitle: Text('إبلاغ عن حادثة أو طوارئ',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  )),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.incidentReporting);
              },
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.dividerDark : AppColors.divider,
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(PhosphorIcons.users(), color: Colors.white),
              ),
              title: Text('إبلاغ عن مفقود',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  )),
              subtitle: Text('الإبلاغ عن شخص مفقود',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  )),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.missingPersonForm);
              },
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}

// ── Navigation Item ──────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              // Keying on (badgeCount, isSelected) re-runs the tween when
              // either changes — gives a subtle "pop" on count increment
              // and a small bounce when the tab is activated.
              key: ValueKey('navitem-$badgeCount-$isSelected'),
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.accent,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? AppColors.accent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.accent
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Center FAB inside nav bar ────────────────────────────────────
class _CenterFab extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _CenterFab({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          PhosphorIcons.plus(),
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
