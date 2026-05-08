import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/services/unread_count_service.dart';
import '../../../app/themes/app_colors.dart';
import '../controllers/notifications_page_controller.dart';
import '../widgets/notification_item.dart';

/// Full-page unified notifications timeline — styled to match the
/// conversations screen so the two feel like the same family of UI.
class NotificationsPage extends GetView<NotificationsPageController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search bar (mirrors ConversationsPage)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textOnDark
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'بحث في الإشعارات...',
                  hintStyle: TextStyle(color: AppColors.textLight),
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                      color: AppColors.primary, size: 20),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Filter chips
          _buildFilterChips(isDark),

          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.notifications.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: AppColors.primary,
                    size: 40,
                  ),
                );
              }

              final items = controller.filteredNotifications;
              if (items.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadNotifications,
                child: AnimationLimiter(
                  child: ListView.builder(
                    itemCount: items.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final entry = items[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          horizontalOffset: 50,
                          child: FadeInAnimation(
                            child: NotificationItem(
                              entry: entry,
                              onTap: () => _handleTap(entry),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _handleTap(NotificationEntry entry) {
    if (entry.type == 'alert' && entry.id != null) {
      controller.markAlertAsRead(entry.id!);
    } else if (entry.type == 'missingPerson') {
      controller.handleMissingPersonTap(entry);
    } else if (entry.type == 'centerReport') {
      controller.handleCenterReportTap(entry);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(color: AppColors.primary),
      ),
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        'الإشعارات',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Unread count pill (mirrors conversations)
        Builder(builder: (context) {
          if (!Get.isRegistered<UnreadCountService>()) {
            return const SizedBox.shrink();
          }
          final unread = Get.find<UnreadCountService>();
          return Obx(() {
            final count = unread.totalUnread;
            if (count <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$count غير مقروءة',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          });
        }),
        IconButton(
          tooltip: 'قراءة الكل',
          onPressed: controller.markAllAsRead,
          icon: Icon(PhosphorIcons.checkCircle(), color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'الكل', 'icon': PhosphorIcons.squaresFour()},
      {'key': 'missingPersons', 'label': 'مفقودون جدد', 'icon': PhosphorIcons.userCircle()},
      {'key': 'centerReports', 'label': 'بلاغات المركز', 'icon': PhosphorIcons.warningOctagon()},
      {'key': 'alerts', 'label': 'التنبيهات', 'icon': PhosphorIcons.eye()},
      {'key': 'messages', 'label': 'الرسائل', 'icon': PhosphorIcons.chatCircle()},
      {'key': 'reports', 'label': 'البلاغات', 'icon': PhosphorIcons.fileText()},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isSelected = controller.selectedFilter.value == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(f['icon'] as IconData, size: 16),
                    label: Text(f['label'] as String),
                    onSelected: (_) => controller.setFilter(f['key'] as String),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }).toList(),
            ),
          )),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(PhosphorIcons.bellRinging(),
                size: 48, color: Colors.white),
          ),
          const Gap(20),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          Text(
            'ستظهر إشعاراتك هنا',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
