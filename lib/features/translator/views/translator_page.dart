import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/audio_visualizer.dart';
import '../../../core/widgets/connection_status_indicator.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/record_button.dart';
import '../controllers/translator_controller.dart';
import '../widgets/message_bubble.dart';

class TranslatorPage extends GetView<TranslatorController> {
  const TranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'مترجم الحرم الفوري',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: AppColors.primary),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: ConnectionStatusIndicator(
                  status: controller.connectionStatus.value,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Gap(16),
            _buildLanguageSelector(isDark)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.1),
            const Gap(16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Obx(
                      () => controller.messages.isEmpty
                          ? _buildEmptyState(isDark)
                          : ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: controller.messages.length,
                              itemBuilder: (context, index) {
                                final messageIndex =
                                    controller.messages.length - 1 - index;
                                final message =
                                    controller.messages[messageIndex];

                                return Column(
                                  children: [
                                    if (message.originalText
                                        .trim()
                                        .isNotEmpty)
                                      MessageBubble(
                                        text: message.originalText,
                                        isOriginal: true,
                                        timestamp: message.timestamp,
                                      ),
                                    if (message.translatedText
                                        .trim()
                                        .isNotEmpty)
                                      MessageBubble(
                                        text: message.translatedText,
                                        isOriginal: false,
                                        timestamp: message.timestamp,
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                  Obx(
                    () => controller.isRecording.value
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: AudioVisualizer(
                              amplitude: controller.audioLevel.value,
                            ),
                          )
                        : const Gap(8),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Obx(
              () => RecordButton(
                isRecording: controller.isRecording.value,
                isLoading: controller.isInitializing.value,
                onPressed: controller.toggleRecording,
                size: 80,
              ),
            ),
            const Gap(12),
            Obx(
              () => Text(
                controller.isRecording.value ? 'اضغط للتوقف' : 'اضغط للبدء',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
            child: Icon(
              PhosphorIcons.translate(),
              size: 48,
              color: Colors.white,
            ),
          ),
          const Gap(20),
          Text(
            'ابدأ الحديث لرؤية الترجمة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),
          const Gap(8),
          Text(
            'اضغط على زر التسجيل أدناه',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildLanguageSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Obx(
                () => LanguageSelector(
                  language: controller.sourceLanguage.value,
                  onTap: controller.goToLanguageSelection,
                ),
              ),
            ),
            const Gap(10),
            // Swap button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                controller.swapLanguages();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.arrowsLeftRight(),
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const Gap(10),
            Flexible(
              child: Obx(
                () => LanguageSelector(
                  language: controller.targetLanguage.value,
                  onTap: controller.goToLanguageSelection,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActions(bool isDark) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(
          bottom: 220,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.currentTranslation.value.isNotEmpty)
            _buildFab(
              heroTag: 'speak',
              icon: PhosphorIcons.speakerHigh(),
              onPressed: controller.speakTranslation,
              gradient: AppColors.successGradient,
              shadowColor: AppColors.success,
            ),
          if (controller.currentTranslation.value.isNotEmpty) const Gap(12),
          _buildFab(
            heroTag: 'history',
            icon: PhosphorIcons.clock(),
            onPressed: controller.goToHistory,
            gradient: AppColors.heroGradient,
            shadowColor: AppColors.primary,
          ),
          const Gap(12),
          _buildFab(
            heroTag: 'settings',
            icon: PhosphorIcons.gear(),
            onPressed: controller.goToSettings,
            gradient: AppColors.warmGradient,
            shadowColor: AppColors.accent,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFab({
    required String heroTag,
    required IconData icon,
    required VoidCallback onPressed,
    required LinearGradient gradient,
    required Color shadowColor,
  }) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
