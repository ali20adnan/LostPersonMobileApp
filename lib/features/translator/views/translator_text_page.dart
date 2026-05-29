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

/// Google-Translate-style text translation page.
/// Polished layout: language pill bar at top (tappable + swap), input card,
/// floating swap button, output card with empty / loading / result states.
class TranslatorTextPage extends GetView<TranslatorController> {
  const TranslatorTextPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowRight()),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'ترجمة النصوص',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.broom()),
              tooltip: 'مسح',
              onPressed: controller.clearInput,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                AnimatedAppear(child: _buildLanguageBar(isDark)),
                const Gap(12),
                Expanded(
                  flex: 5,
                  child: AnimatedAppear(
                    delay: const Duration(milliseconds: 80),
                    child: _buildInputCard(isDark),
                  ),
                ),
                const Gap(8),
                AnimatedAppear(
                  delay: const Duration(milliseconds: 140),
                  child: _buildSwapButton(isDark),
                ),
                const Gap(8),
                Expanded(
                  flex: 5,
                  child: AnimatedAppear(
                    delay: const Duration(milliseconds: 180),
                    child: _buildOutputCard(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top language bar: [source pill] ⇄ [target pill] ────────────
  Widget _buildLanguageBar(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _languagePill(
              label: controller.sourceLanguage.value.nameAr,
              isDark: isDark,
              onTap: () =>
                  controller.openLanguagePicker(isSource: true),
            ),
          ),
        ),
        const Gap(8),
        Icon(
          PhosphorIcons.arrowsLeftRight(),
          size: 18,
          color: isDark
              ? AppColors.textOnDarkSecondary
              : AppColors.textSecondary,
        ),
        const Gap(8),
        Expanded(
          child: Obx(
            () => _languagePill(
              label: controller.targetLanguage.value.nameAr,
              isDark: isDark,
              onTap: () =>
                  controller.openLanguagePicker(isSource: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _languagePill({
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textOnDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const Gap(6),
              Icon(
                PhosphorIcons.caretDown(),
                size: 14,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Center swap button (mirror source ↔ target) ────────────────
  Widget _buildSwapButton(bool isDark) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            controller.swapLanguages();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.swap_vert_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ── Input card ─────────────────────────────────────────────────
  Widget _buildInputCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.pencilSimple(),
                size: 14,
                color: AppColors.accent,
              ),
              const Gap(6),
              Obx(
                () => Text(
                  controller.sourceLanguage.value.nameAr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Expanded(
            child: TextField(
              controller: controller.inputController,
              autofocus: true,
              maxLines: null,
              minLines: null,
              maxLength: 5000,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              cursorColor: AppColors.primary,
              cursorWidth: 1.6,
              style: TextStyle(
                fontSize: 19,
                height: 1.5,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                // Explicitly disable ALL border states so the global
                // InputDecorationTheme's focused outline doesn't paint a
                // navy box around the text area while the user types.
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                hintText: 'اطبع نصّك هنا للترجمة...',
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 17,
                ),
                counterText: '',
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Gap(6),
          Divider(
            height: 1,
            color: (isDark ? AppColors.cardBorderDark : AppColors.cardBorder)
                .withValues(alpha: 0.6),
          ),
          const Gap(4),
          Obx(() {
            final hasText = controller.inputText.value.isNotEmpty;
            return Row(
              children: [
                _iconAction(
                  icon: PhosphorIcons.x(),
                  tooltip: 'مسح',
                  onTap: hasText ? controller.clearInput : null,
                  isDark: isDark,
                ),
                _iconAction(
                  icon: PhosphorIcons.speakerHigh(),
                  tooltip: 'استماع',
                  onTap: hasText ? controller.speakInput : null,
                  isDark: isDark,
                ),
                _iconAction(
                  icon: PhosphorIcons.copy(),
                  tooltip: 'نسخ',
                  onTap: hasText ? controller.copyInput : null,
                  isDark: isDark,
                ),
                const Spacer(),
                Text(
                  '${controller.inputText.value.length}/5000',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasText
                        ? (isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary)
                        : AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Output card ────────────────────────────────────────────────
  Widget _buildOutputCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceSunkenDark
            : AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.translate(),
                size: 14,
                color: AppColors.primary,
              ),
              const Gap(6),
              Obx(
                () => Text(
                  controller.targetLanguage.value.nameAr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Expanded(
            child: Obx(() {
              final translation = controller.currentTranslation.value;
              final loading = controller.isTranslatingText.value;

              Widget body;
              if (loading && translation.isEmpty) {
                body = _buildLoadingState(key: 'loading', isDark: isDark);
              } else if (translation.isEmpty) {
                body = _buildEmptyOutput(key: 'empty', isDark: isDark);
              } else {
                body = _buildTranslationText(
                  key: 'text-${translation.hashCode}',
                  text: translation,
                  isDark: isDark,
                );
              }

              return AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: AppMotion.emphasizedCurve,
                child: body,
              );
            }),
          ),
          const Gap(6),
          Divider(
            height: 1,
            color: (isDark ? AppColors.cardBorderDark : AppColors.cardBorder)
                .withValues(alpha: 0.6),
          ),
          const Gap(4),
          Obx(() {
            final hasText =
                controller.currentTranslation.value.trim().isNotEmpty;
            return Row(
              children: [
                _iconAction(
                  icon: PhosphorIcons.speakerHigh(),
                  tooltip: 'استماع',
                  onTap: hasText ? controller.speakTranslation : null,
                  isDark: isDark,
                  highlight: true,
                ),
                _iconAction(
                  icon: PhosphorIcons.copy(),
                  tooltip: 'نسخ',
                  onTap: hasText ? controller.copyTranslation : null,
                  isDark: isDark,
                ),
                const Spacer(),
                if (controller.isTranslatingText.value && hasText)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyOutput({required String key, required bool isDark}) {
    return Center(
      key: ValueKey(key),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.translate(),
            size: 36,
            color: AppColors.textLight.withValues(alpha: 0.7),
          ),
          const Gap(8),
          Text(
            'ستظهر الترجمة هنا',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState({required String key, required bool isDark}) {
    return Center(
      key: ValueKey(key),
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTranslationText({
    required String key,
    required String text,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      key: ValueKey(key),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 19,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        ),
      ).animate().fadeIn(duration: AppMotion.standard),
    );
  }

  // ── Reusable inline icon action ─────────────────────────────────
  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    required bool isDark,
    bool highlight = false,
  }) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.textLight.withValues(alpha: 0.4)
        : highlight
            ? AppColors.primary
            : (isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 21, color: color),
          ),
        ),
      ),
    );
  }
}
