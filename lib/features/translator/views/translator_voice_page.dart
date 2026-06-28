import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/audio_visualizer.dart';
import '../../../core/widgets/record_button.dart';
import '../controllers/translator_controller.dart';

/// Google-Translate-style voice page (Image 4).
/// - Recording starts MANUALLY (user taps the mic in this screen).
/// - On stop, transcripts and translations stay visible until user backs out.
class TranslatorVoicePage extends GetView<TranslatorController> {
  const TranslatorVoicePage({super.key});

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
            onPressed: () async {
              if (controller.isRecording.value) {
                await controller.stopRecording();
              }
              Get.back();
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildTitle(isDark),
                const Gap(16),
                Expanded(
                  child: _buildTranscriptArea(isDark),
                ),
                _buildLanguagesRow(isDark),
                const Gap(20),
                _buildRecordButton(),
                const Gap(28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Obx(
        () => Text(
          controller.isRecording.value
              ? 'التحدّث الآن...'
              : 'اضغط لبدء التحدّث',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: controller.isRecording.value
                ? AppColors.accent
                : (isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptArea(bool isDark) {
    return SingleChildScrollView(
      child: Obx(() {
        final transcription = controller.currentTranscription.value;
        final translation = controller.currentTranslation.value;

        if (transcription.isEmpty && translation.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.waveform(),
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const Gap(8),
                    Text(
                      'تحويل الصوت إلى نص',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (transcription.isNotEmpty)
              SelectableText(
                transcription,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
            if (translation.isNotEmpty) ...[
              const Gap(20),
              SelectableText(
                translation,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
            if (controller.isRecording.value) ...[
              const Gap(16),
              AudioVisualizer(amplitude: controller.audioLevel.value),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildLanguagesRow(bool isDark) {
    return Obx(() {
      final disabled = controller.isRecording.value;
      return Row(
        children: [
          Expanded(
            child: _buildLanguageChip(
              controller.sourceLanguage.value.nameAr,
              isDark: isDark,
              disabled: disabled,
            ),
          ),
          const Gap(12),
          Icon(
            PhosphorIcons.arrowLeft(),
            size: 18,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
          const Gap(12),
          Expanded(
            child: _buildLanguageChip(
              controller.targetLanguage.value.nameAr,
              isDark: isDark,
              disabled: disabled,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLanguageChip(
    String label, {
    required bool isDark,
    required bool disabled,
  }) {
    return Container(
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
            color: disabled
                ? AppColors.textLight
                : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    return Obx(
      () => RecordButton(
        isRecording: controller.isRecording.value,
        isLoading: controller.isInitializing.value,
        onPressed: controller.toggleRecording,
        size: 84,
      ),
    );
  }
}
