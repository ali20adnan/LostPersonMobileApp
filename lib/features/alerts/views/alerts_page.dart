import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_translator_app/core/utils/icon_direction.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/alerts_controller.dart';
import '../widgets/alert_card.dart';

/// Full page displaying all alerts with filters
class AlertsPage extends GetView<AlertsController> {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(child: _buildFilterChips(theme, isDark)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: Obx(() => _buildAlertList(theme, isDark)),
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
        Obx(() => controller.unreadCount.value > 0
            ? TextButton.icon(
                onPressed: controller.markAllAsRead,
                icon: Icon(PhosphorIcons.checkCircle().ltr, size: 16),
                label: const Text('قراءة الكل', style: TextStyle(fontSize: 12)),
              )
            : const SizedBox.shrink()),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(color: AppColors.primary),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(PhosphorIcons.eye(), color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'التنبيهات والمشاهدات',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(() => Text(
                                  '${controller.totalItems} تنبيه • ${controller.unreadCount.value} غير مقروء',
                                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                ],
              ),
            ),
          ),
          ],
        ),
        titlePadding: const EdgeInsets.only(right: 16, bottom: 14),
        title: const Text(
          'التنبيهات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    final types = [
      {'key': null, 'label': 'الكل'},
      {'key': 'found', 'label': 'تم العثور'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: types.map((t) {
                final isSelected = controller.selectedType.value == t['key'];
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(t['label'] as String),
                    onSelected: (_) => controller.setTypeFilter(t['key']),
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

  Widget _buildAlertList(ThemeData theme, bool isDark) {
    if (controller.isLoading.value && controller.alerts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.alerts.isEmpty) {
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
                child: Icon(PhosphorIcons.eye(), size: 56, color: AppColors.primary),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                'لا توجد تنبيهات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم عرض التنبيهات والمشاهدات هنا',
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
          if (index == controller.alerts.length - 1) {
            controller.loadMore();
          }
          final alert = controller.alerts[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: AlertCard(
                  alert: alert,
                  onTap: () => controller.markAsRead(alert.id),
                ),
              ),
            ),
          );
        },
        childCount: controller.alerts.length,
      ),
    );
  }
}
