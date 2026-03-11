import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../notifications/views/notification_overlay.dart';
import '../../notifications/controllers/notifications_controller.dart';
import '../../messaging/controllers/conversations_controller.dart';
import '../../messaging/views/messaging_overlay.dart';
import '../../../app/routes/app_routes.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              // Main content with animated switching
              Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(controller.currentIndex.value),
                      child: controller.pages[controller.currentIndex.value],
                    ),
                  )),

              // Tap barrier to close notification overlay
              const NotificationDismissBarrier(),

              // Floating notification bell at top-left
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: const NotificationOverlay(),
              ),

              // Floating messaging icon at top-right
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: const MessagingOverlay(),
              ),
            ],
          ),
      // Center docked FAB - independent, opens incident creation form
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: SizedBox(
        height: 46,
        width: 46,
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _closeOverlays();
            Get.toNamed(AppRoutes.incidentReporting);
          },
          elevation: 2,
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF1A1A2E),
          foregroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF1A1A2E)
              : Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 26),
        ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Obx(
        () => BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          height: 70,
          padding: EdgeInsets.zero,
          elevation: 0,
          color: const Color(0xFF1A1A2E),
          surfaceTintColor: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavIcon(
                icon: Icons.translate_rounded,
                label: 'الترجمة',
                isSelected: controller.currentIndex.value == 0,
                onTap: () => _onTabTap(0),
                theme: theme,
              ),
              _BottomNavIcon(
                icon: Icons.group_outlined,
                activeIcon: Icons.group,
                label: 'المفقودون',
                isSelected: controller.currentIndex.value == 1,
                onTap: () => _onTabTap(1),
                theme: theme,
              ),
              const SizedBox(width: 48), // gap for FAB
              _BottomNavIcon(
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'البلاغات',
                isSelected: controller.currentIndex.value == 2,
                onTap: () => _onTabTap(2),
                theme: theme,
              ),
              _BottomNavIcon(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'حسابي',
                isSelected: controller.currentIndex.value == 3,
                onTap: () => _onTabTap(3),
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    ),

    // Messaging dismiss barrier - OUTSIDE Scaffold, covers everything
    const MessagingDismissBarrier(),

    // Instagram-style slide-in messaging panel - OUTSIDE Scaffold
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
}

/// Bottom navigation icon widget with label
class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _BottomNavIcon({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.white
        : Colors.white54;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? (activeIcon ?? icon) : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
