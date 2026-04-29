import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/services/unread_count_service.dart';
import '../controllers/notifications_page_controller.dart';
import '../widgets/notification_item.dart';

/// Full-page unified notifications timeline
class NotificationsPage extends GetView<NotificationsPageController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(child: _buildFilterChips(theme, isDark)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: Obx(() => _buildNotificationList(theme, isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      leading: IconButton(
        icon: Icon(PhosphorIcons.arrowRight()),
        onPressed: () => Get.back(),
      ),
      actions: [
        TextButton.icon(
          onPressed: controller.markAllAsRead,
          icon: Icon(PhosphorIcons.checkCircle(), size: 16),
          label: const Text('قراءة الكل', style: TextStyle(fontSize: 12)),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(PhosphorIcons.bell(), color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مركز الإشعارات',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Builder(builder: (context) {
                          if (!Get.isRegistered<UnreadCountService>()) {
                            return const SizedBox.shrink();
                          }
                          final unread = Get.find<UnreadCountService>();
                          return Obx(() => Text(
                                '${unread.totalUnread} إشعار غير مقروء',
                                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                              ));
                        }),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(right: 16, bottom: 14),
        title: const Text(
          'الإشعارات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'الكل', 'icon': PhosphorIcons.squaresFour()},
      {'key': 'missingPersons', 'label': 'مفقودون جدد', 'icon': PhosphorIcons.userCircle()},
      {'key': 'centerReports', 'label': 'بلاغات المركز', 'icon': PhosphorIcons.warningOctagon()},
      {'key': 'alerts', 'label': 'التنبيهات', 'icon': PhosphorIcons.eye()},
      {'key': 'messages', 'label': 'الرسائل', 'icon': PhosphorIcons.chatCircle()},
      {'key': 'reports', 'label': 'البلاغات', 'icon': PhosphorIcons.fileText()},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isSelected = controller.selectedFilter.value == f['key'];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    selected: isSelected,
                    avatar: Icon(f['icon'] as IconData, size: 16),
                    label: Text(f['label'] as String),
                    onSelected: (_) => controller.setFilter(f['key'] as String),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }).toList(),
            ),
          )),
    );
  }

  Widget _buildNotificationList(ThemeData theme, bool isDark) {
    if (controller.isLoading.value && controller.notifications.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = controller.filteredNotifications;

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.secondary.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Icon(PhosphorIcons.bellRinging(), size: 56, color: AppColors.primary),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                'لا توجد إشعارات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ستظهر إشعاراتك هنا',
                style: TextStyle(
                  color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = filtered[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: NotificationItem(
                  entry: entry,
                  onTap: () {
                    if (entry.type == 'alert' && entry.id != null) {
                      controller.markAlertAsRead(entry.id!);
                    } else if (entry.type == 'missingPerson') {
                      controller.handleMissingPersonTap(entry);
                    } else if (entry.type == 'centerReport') {
                      controller.handleCenterReportTap(entry);
                    }
                  },
                ),
              ),
            ),
          );
        },
        childCount: filtered.length,
      ),
    );
  }
}
