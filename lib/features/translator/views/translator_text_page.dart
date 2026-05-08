import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/translator_controller.dart';

/// Google-Translate-style text translation page (Image 2).
/// Two stacked cards: input on top, translation below.
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
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.x()),
              tooltip: 'مسح',
              onPressed: () {
                controller.clearInput();
                Get.back();
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildInputCard(isDark),
                ),
                const Gap(12),
                Expanded(
                  flex: 1,
                  child: _buildOutputCard(isDark),
                ),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
          Obx(
            () => Text(
              controller.sourceLanguage.value.nameAr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Gap(6),
          Expanded(
            child: TextField(
              controller: controller.inputController,
              autofocus: true,
              maxLines: null,
              minLines: 4,
              maxLength: 5000,
              expands: false,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontSize: 18,
                height: 1.45,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
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
          const Gap(4),
          Divider(
            height: 1,
            color: (isDark ? AppColors.cardBorderDark : AppColors.cardBorder)
                .withValues(alpha: 0.6),
          ),
          const Gap(6),
          Row(
            children: [
              _iconAction(
                icon: PhosphorIcons.copy(),
                tooltip: 'نسخ',
                onTap: controller.copyInput,
                isDark: isDark,
              ),
              const Gap(4),
              _iconAction(
                icon: PhosphorIcons.speakerHigh(),
                tooltip: 'استماع',
                onTap: controller.speakInput,
                isDark: isDark,
              ),
              const Gap(4),
              _iconAction(
                icon: PhosphorIcons.x(),
                tooltip: 'مسح',
                onTap: controller.clearInput,
                isDark: isDark,
              ),
              const Spacer(),
              Obx(
                () => Text(
                  '${controller.inputText.value.length}/5000',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Text(
              controller.targetLanguage.value.nameAr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Gap(6),
          Expanded(
            child: SingleChildScrollView(
              child: Obx(() {
                if (controller.isTranslatingText.value &&
                    controller.currentTranslation.value.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  );
                }

                final translation = controller.currentTranslation.value;
                if (translation.isEmpty) {
                  return Text(
                    'ستظهر الترجمة هنا',
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.textLight,
                    ),
                  );
                }

                return SelectableText(
                  translation,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textOnDark
                        : AppColors.textPrimary,
                  ),
                );
              }),
            ),
          ),
          const Gap(4),
          Divider(
            height: 1,
            color: (isDark ? AppColors.cardBorderDark : AppColors.cardBorder)
                .withValues(alpha: 0.6),
          ),
          const Gap(6),
          Obx(() {
            final hasText =
                controller.currentTranslation.value.trim().isNotEmpty;
            return Row(
              children: [
                _iconAction(
                  icon: PhosphorIcons.copy(),
                  tooltip: 'نسخ',
                  onTap: hasText ? controller.copyTranslation : null,
                  isDark: isDark,
                ),
                const Gap(4),
                _iconAction(
                  icon: PhosphorIcons.speakerHigh(),
                  tooltip: 'استماع',
                  onTap: hasText ? controller.speakTranslation : null,
                  isDark: isDark,
                  highlight: true,
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

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    required bool isDark,
    bool highlight = false,
  }) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.textLight.withValues(alpha: 0.5)
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
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}
