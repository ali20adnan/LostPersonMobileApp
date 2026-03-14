import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../data/models/missing_person_report_model.dart';
import '../controllers/missing_persons_controller.dart';
import '../widgets/missing_person_card.dart';

class MissingPersonsPage extends GetView<MissingPersonsController> {
  const MissingPersonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(child: _buildSearchBar(theme, isDark)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _buildTabs(theme, isDark),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Obx(() => _buildTabContent(theme, isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(color: AppColors.primary),
        ),
      ),
      title: const Text(
        'الأشخاص المفقودون',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
    );
  }



  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: controller.updateSearch,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو البلد أو الوصف...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: Icon(Iconsax.search_normal_1, color: AppColors.primary, size: 20),
          filled: true,
          fillColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceSunken,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTabs(ThemeData theme, bool isDark) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildTab(isDark, 'المبلغ عنهم', Iconsax.search_normal, 0,
                controller.reportedPersons.length),
            _buildTab(isDark, 'تم العثور', Iconsax.tick_circle, 1,
                controller.foundPersons.length),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(bool isDark, String label, IconData icon, int index, int count) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.heroGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textLight),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme, bool isDark) {
    final tab = controller.selectedTab.value;
    if (tab == 0) {
      return _buildPersonList(theme, isDark, controller.filteredReportedPersons, isFound: false);
    }
    return _buildPersonList(theme, isDark, controller.filteredFoundPersons, isFound: true);
  }

  Widget _buildPersonList(
    ThemeData theme,
    bool isDark,
    List<MissingPersonReport> persons, {
    required bool isFound,
  }) {
    if (persons.isEmpty) {
      final hasSearch = controller.searchQuery.value.isNotEmpty;
      return _buildEmptyState(
        isDark,
        hasSearch
            ? Iconsax.search_normal
            : (isFound ? Iconsax.tick_circle : Iconsax.search_status),
        hasSearch
            ? 'لا توجد نتائج'
            : (isFound ? 'لا يوجد أشخاص تم العثور عليهم' : 'لا توجد بلاغات حالياً'),
        hasSearch
            ? 'جرب تغيير كلمة البحث'
            : (isFound
                ? 'سيتم عرض الأشخاص الذين تم العثور عليهم هنا'
                : 'سيتم عرض البلاغات عن المفقودين هنا'),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: persons.length,
        itemBuilder: (context, index) {
          final person = persons[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: MissingPersonCard(
                  person: person,
                  isFound: isFound,
                  onMarkFound: isFound ? null : () => controller.markAsFound(person),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: Icon(icon, size: 56, color: AppColors.primary),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
