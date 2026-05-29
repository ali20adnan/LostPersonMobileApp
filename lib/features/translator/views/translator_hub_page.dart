import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_motion.dart';
import '../../../core/widgets/shared/motion/animated_appear.dart';
import '../controllers/translator_controller.dart';

/// Hub screen — the new main translator surface (Image 1).
/// Big tap target opens the text page; mic + camera buttons sit at the
/// bottom; languages row sits above the action buttons.
class TranslatorHubPage extends GetView<TranslatorController> {
  const TranslatorHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: Text(
            'مترجم الحرم الفوري',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedAppear(
                  child: _buildTextTapArea(isDark),
                ),
              ),
              AnimatedAppear(
                delay: const Duration(milliseconds: 120),
                child: _buildLanguagesRow(isDark),
              ),
              const Gap(16),
              AnimatedAppear(
                delay: const Duration(milliseconds: 200),
                child: _buildActionButtons(isDark),
              ),
              const Gap(28),
            ],
          ),
        ),
      ),
    );
  }

  // ── Big "Translate text" tap area ──────────────────────────────

  Widget _buildTextTapArea(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: controller.openTextPage,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          alignment: AlignmentDirectional.topStart,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIcons.pencilSimple(),
                size: 22,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  'ترجمة النص',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              _buildPasteChip(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasteChip(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          controller.pasteAndOpenText();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.clipboard(),
                size: 16,
                color: AppColors.accent,
              ),
              const Gap(6),
              Text(
                'لصق',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Languages row ──────────────────────────────────────────────

  Widget _buildLanguagesRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _buildLanguageButton(
                controller.sourceLanguage.value.nameAr,
                isDark: isDark,
                onTap: () =>
                    controller.openLanguagePicker(isSource: true),
              ),
            ),
          ),
          const Gap(10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.swapLanguages();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDark.withValues(alpha: 0.7)
                    : AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                PhosphorIcons.arrowsLeftRight(),
                size: 20,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Obx(
              () => _buildLanguageButton(
                controller.targetLanguage.value.nameAr,
                isDark: isDark,
                onTap: () =>
                    controller.openLanguagePicker(isSource: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
    String label, {
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Action buttons (camera + mic) ──────────────────────────────

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSecondaryAction(
            icon: PhosphorIcons.camera(),
            label: 'الكاميرا',
            isDark: isDark,
            onTap: controller.openCameraAndScan,
          ),
          _buildMicButton(),
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDark.withValues(alpha: 0.7)
                    : AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.cardBorderDark
                      : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const Gap(8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        controller.openVoicePage();
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          PhosphorIcons.microphone(PhosphorIconsStyle.fill),
          size: 38,
          color: Colors.black87,
        ),
      ),
    )
        .animate(delay: const Duration(milliseconds: 280))
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: AppMotion.emphasized,
          curve: AppMotion.emphasizedCurve,
        )
        .fadeIn(duration: AppMotion.standard);
  }
}
