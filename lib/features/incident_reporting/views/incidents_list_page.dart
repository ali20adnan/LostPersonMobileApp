import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  /// When true the page omits its own AppBar — used inside the merged
  /// "البلاغات" hub, which provides a single shared header.
  final bool embedded;

  const IncidentsListPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: embedded ? null : _buildAppBar(),
      body: Column(
        children: [
          // Search + filter section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.cardBorderDark
                            : AppColors.cardBorder,
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
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
                        prefixIcon: Icon(
                          PhosphorIcons.magnifyingGlass(),
                          size: 20,
                          color: isDark ? AppColors.accentLight : AppColors.primary,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textLight,
                        ),
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
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        gradient: hasFilter ? AppColors.heroGradient : null,
                        color: hasFilter
                            ? null
                            : isDark
                                ? AppColors.cardDark
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasFilter
                              ? Colors.transparent
                              : isDark
                                  ? AppColors.cardBorderDark
                                  : AppColors.cardBorder,
                        ),
                        boxShadow: hasFilter ? null : AppColors.cardShadow,
                      ),
                      child: Badge(
                        isLabelVisible: hasFilter,
                        backgroundColor: AppColors.accent,
                        smallSize: 8,
                        child: Icon(
                          PhosphorIcons.funnelSimple(),
                          size: 20,
                          color: hasFilter
                              ? Colors.white
                              : isDark
                                  ? AppColors.accentLight
                                  : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 72,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      centerTitle: true,
      // Reserve space for HomePage floating notification / messaging buttons.
      leading: const SizedBox(width: 56),
      actions: const [SizedBox(width: 56)],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'قائمة الإبلاغات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(
            begin: -0.15,
            curve: Curves.easeOutCubic,
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
