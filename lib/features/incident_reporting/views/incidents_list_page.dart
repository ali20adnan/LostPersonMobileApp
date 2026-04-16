import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/incidents_list_controller.dart';
import '../widgets/incident_card_widget.dart';
import '../../../core/constants/incident_constants.dart';

/// Page displaying list of reports with filtering
class IncidentsListPage extends GetView<IncidentsListController> {
  const IncidentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('قائمة الإبلاغات'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: AppColors.primary),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search + filter section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar + filter button row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: controller.updateSearch,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ابحث بالعنوان أو الوصف أو الموقع...',
                          hintTextDirection: TextDirection.rtl,
                          prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                              size: 20, color: AppColors.primary),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceElevatedDark
                              : AppColors.surfaceSunken,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.cardBorderDark
                                  : AppColors.cardBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 16,
                          ),
                          isDense: true,
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Obx(() {
                      final hasFilter =
                          controller.selectedStatusFilter.value != null ||
                              controller.selectedTypeFilter.value != null;
                      return GestureDetector(
                        onTap: () => _showFilterSheet(context, isDark),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient:
                                hasFilter ? AppColors.heroGradient : null,
                            color: hasFilter
                                ? null
                                : isDark
                                    ? AppColors.surfaceElevatedDark
                                    : AppColors.surfaceSunken,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasFilter
                                  ? Colors.transparent
                                  : isDark
                                      ? AppColors.cardBorderDark
                                      : AppColors.cardBorder,
                            ),
                          ),
                          child: Badge(
                            isLabelVisible: hasFilter,
                            backgroundColor: Colors.white,
                            smallSize: 8,
                            child: Icon(
                              PhosphorIcons.funnelSimple(),
                              size: 20,
                              color: hasFilter
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Reports list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: AppColors.primary,
                    size: 40,
                  ),
                );
              }

              final reports = controller.filteredReports;
              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(PhosphorIcons.file(),
                            size: 48, color: Colors.white),
                      ),
                      const Gap(16),
                      Text('لا توجد بلاغات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textPrimary,
                          )),
                      const Gap(8),
                      Text('جرب تغيير الفلاتر أو أضف بلاغ جديد',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary,
                          )),
                    ],
                  ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.refreshReports,
                child: AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: reports.length + (controller.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == reports.length) {
                        controller.loadMore();
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: LoadingAnimationWidget.threeArchedCircle(
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        );
                      }
                      final report = reports[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 40,
                          child: FadeInAnimation(
                            child: IncidentCardWidget(
                              incident: report,
                              onTap: () =>
                                  controller.navigateToReportDetail(report.id),
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

  void _showFilterSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text(
              'تصفية البلاغات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const Gap(16),
            Text(
              'الحالة',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSheetChip(
                      'الكل',
                      controller.selectedStatusFilter.value == null,
                      () => controller.filterByStatus(null),
                      isDark: isDark,
                    ),
                    ...ReportStatus.values.map((s) => _buildSheetChip(
                          s.displayNameAr,
                          controller.selectedStatusFilter.value == s,
                          () => controller.filterByStatus(s),
                          isDark: isDark,
                        )),
                  ],
                )),
            const Gap(16),
            Text(
              'النوع',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSheetChip(
                      'الكل',
                      controller.selectedTypeFilter.value == null,
                      () => controller.filterByType(null),
                      isDark: isDark,
                    ),
                    ...ReportType.values.map((t) => _buildSheetChip(
                          t.displayNameAr,
                          controller.selectedTypeFilter.value == t,
                          () => controller.filterByType(t),
                          icon: t.icon,
                          isDark: isDark,
                        )),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.heroGradient : null,
          color: isSelected
              ? null
              : isDark
                  ? AppColors.cardDark
                  : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDark
                    ? AppColors.cardBorderDark
                    : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15,
                  color: isSelected ? Colors.white : AppColors.primary),
              const Gap(6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppColors.textOnDark
                        : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
