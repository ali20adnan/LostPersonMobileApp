import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/languages_controller.dart';
import '../widgets/language_card.dart';

class LanguagesPage extends GetView<LanguagesController> {
  const LanguagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: const Text(
            'اختيار اللغة',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3),
            onPressed: () => Get.back(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildSectionHeader(
                    isDark,
                    'اللغة المصدر',
                    'Source Language',
                    Iconsax.microphone,
                  ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05),
                  const Gap(8),
                  Obx(() => _buildLanguageList(isDark, isSource: true)),
                  const Gap(20),
                  _buildSwapButton(isDark)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
                  const Gap(20),
                  _buildSectionHeader(
                    isDark,
                    'اللغة الهدف',
                    'Target Language',
                    Iconsax.translate,
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideX(begin: 0.05),
                  const Gap(8),
                  Obx(() => _buildLanguageList(isDark, isSource: false)),
                  const Gap(100),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildSaveButton(isDark),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildSectionHeader(
    bool isDark,
    String titleAr,
    String titleEn,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleAr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              Text(
                titleEn,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList(bool isDark, {required bool isSource}) {
    final selectedLanguage = isSource
        ? controller.selectedSourceLanguage.value
        : controller.selectedTargetLanguage.value;

    return Column(
      children: controller.availableLanguages.map((language) {
        final isSelected = language.code == selectedLanguage.code;

        return LanguageCard(
          language: language,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.lightImpact();
            if (isSource) {
              controller.selectSourceLanguage(language);
            } else {
              controller.selectTargetLanguage(language);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSwapButton(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.swapLanguages();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.arrow_swap_horizontal,
                    color: Colors.white, size: 18),
              ),
              const Gap(10),
              Text(
                'تبديل اللغات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            controller.saveAndGoBack();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
              Gap(10),
              Text(
                'حفظ التغييرات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
