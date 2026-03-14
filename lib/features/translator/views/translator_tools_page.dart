import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/audio_visualizer.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/record_button.dart';
import '../../ocr_reader/controllers/ocr_reader_controller.dart';
import '../controllers/translator_controller.dart';
import '../widgets/message_bubble.dart';

class TranslatorToolsPage extends GetView<TranslatorController> {
  const TranslatorToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.surfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme, isDark, context),
              const Gap(12),
              _buildModeSwitcher(theme, isDark),
              const Gap(16),
              Expanded(
                child: Obx(() => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: controller.toolMode.value == 0
                          ? KeyedSubtree(
                              key: const ValueKey(0),
                              child: _buildTranslatorContent(theme, isDark),
                            )
                          : KeyedSubtree(
                              key: const ValueKey(1),
                              child: _buildOcrContent(theme, isDark),
                            ),
                    )),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(() => controller.toolMode.value == 0
          ? _buildTranslatorFabs(isDark)
          : const SizedBox.shrink()),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, bool isDark, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 12, 60, 12),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Obx(() => Text(
                  controller.toolMode.value == 0
                      ? 'مترجم الحرم الفوري'
                      : 'قارئ اللافتات',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                )),
          ),
          // Connection indicator (voice mode only)
          Obx(() {
            if (controller.toolMode.value == 0 &&
                controller.isRecording.value) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      'مباشر',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                    begin: 0.7,
                    end: 1.0,
                    duration: 1200.ms,
                  );
            }
            return const SizedBox.shrink();
          }),
          // OCR info button
          Obx(() {
            if (controller.toolMode.value == 1) {
              return IconButton(
                icon: Icon(Iconsax.info_circle,
                    color: isDark
                        ? AppColors.textOnDark
                        : AppColors.textSecondary),
                onPressed: () => _showOcrInfoDialog(context),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  // ── Mode Switcher ─────────────────────────────────────────────

  Widget _buildModeSwitcher(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final selected = controller.toolMode.value;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              _buildModeTab(
                theme: theme,
                isDark: isDark,
                icon: Iconsax.microphone,
                label: 'مترجم صوتي',
                isSelected: selected == 0,
                onTap: () => _switchMode(0),
              ),
              _buildModeTab(
                theme: theme,
                isDark: isDark,
                icon: Iconsax.scan,
                label: 'قارئ نصوص',
                isSelected: selected == 1,
                onTap: () => _switchMode(1),
              ),
            ],
          ),
        );
      }),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildModeTab({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.heroGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? AppColors.buttonShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
              ),
              const Gap(8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchMode(int mode) {
    if (controller.isRecording.value) {
      Get.snackbar(
        'تنبيه',
        'يجب إيقاف التسجيل أولاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        duration: const Duration(seconds: 2),
        icon: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Iconsax.warning_2, color: Colors.white),
        ),
      );
      return;
    }
    controller.toolMode.value = mode;
  }

  // ── Voice Translator Content ──────────────────────────────────

  Widget _buildTranslatorContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Language selector
        _buildLanguageSelector(theme, isDark),
        const Gap(12),

        // Messages
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Obx(
                  () => controller.messages.isEmpty
                      ? _buildEmptyVoiceState(theme, isDark)
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: controller.messages.length,
                          itemBuilder: (context, index) {
                            final messageIndex =
                                controller.messages.length - 1 - index;
                            final message = controller.messages[messageIndex];
                            return Column(
                              children: [
                                if (message.originalText.trim().isNotEmpty)
                                  MessageBubble(
                                    text: message.originalText,
                                    isOriginal: true,
                                    timestamp: message.timestamp,
                                  ),
                                if (message.translatedText.trim().isNotEmpty)
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
              // Audio visualizer
              Obx(
                () => controller.isRecording.value
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AudioVisualizer(
                          amplitude: controller.audioLevel.value,
                        ),
                      )
                    : const SizedBox(height: 8),
              ),
            ],
          ),
        ),

        const Gap(8),

        // Record button with hint
        _buildRecordSection(theme, isDark),

        const Gap(16),
      ],
    );
  }

  Widget _buildEmptyVoiceState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Iconsax.message,
              size: 44,
              color: Colors.white,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms),
          const Gap(24),
          Text(
            'ابدأ الحديث لرؤية الترجمة',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'اضغط زر التسجيل بالأسفل للبدء',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.textOnDarkSecondary.withValues(alpha: 0.6) : AppColors.textLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildLanguageSelector(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => LanguageSelector(
                  language: controller.sourceLanguage.value,
                  onTap: controller.goToLanguageSelection,
                ),
              ),
            ),
            const Gap(8),
            // Swap button with gradient
            GestureDetector(
              onTap: controller.swapLanguages,
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
                child: const Icon(
                  Iconsax.arrow_swap_horizontal,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const Gap(8),
            Expanded(
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
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecordSection(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Obx(
          () => RecordButton(
            isRecording: controller.isRecording.value,
            isLoading: controller.isInitializing.value,
            onPressed: controller.toggleRecording,
            size: 76,
          ),
        ),
        const Gap(10),
        Obx(
          () => AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: theme.textTheme.bodyMedium!.copyWith(
              color: controller.isRecording.value
                  ? AppColors.accent
                  : isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
              fontWeight: controller.isRecording.value
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            child: Text(
              controller.isRecording.value ? 'اضغط للتوقف' : 'اضغط للبدء',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslatorFabs(bool isDark) {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.currentTranslation.value.isNotEmpty)
            _buildGradientFab(
              heroTag: 'speak',
              icon: Iconsax.volume_high,
              gradient: AppColors.accentGradient,
              onPressed: controller.speakTranslation,
            ),
          if (controller.currentTranslation.value.isNotEmpty) const Gap(12),
          _buildGradientFab(
            heroTag: 'history',
            icon: Iconsax.clock,
            gradient: AppColors.heroGradient,
            onPressed: controller.goToHistory,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideX(begin: -0.3, end: 0);
  }

  Widget _buildGradientFab({
    required String heroTag,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(26),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // ── OCR Text Reader Content ───────────────────────────────────

  Widget _buildOcrContent(ThemeData theme, bool isDark) {
    final ocrCtrl = Get.find<OcrReaderController>();

    return Stack(
      children: [
        Column(
          children: [
            // Language selector for OCR
            _buildOcrLanguageSelector(theme, isDark, ocrCtrl),

            const Gap(12),

            // Image preview with tappable text block overlays
            Expanded(
              child: Obx(() {
                final imagePath = ocrCtrl.capturedImagePath.value;
                final blocks = ocrCtrl.recognizedBlocks.toList();
                final selected = ocrCtrl.selectedBlockIndices.toSet();
                final imgSize = ocrCtrl.imageSize.value;
                final scanning = ocrCtrl.isScanning.value;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A1A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        if (imagePath.isNotEmpty)
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.file(
                                        File(imagePath),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    if (blocks.isNotEmpty &&
                                        imgSize != Size.zero)
                                      ..._buildBlockOverlays(
                                        constraints.biggest,
                                        imgSize,
                                        blocks,
                                        selected,
                                        ocrCtrl,
                                      ),
                                  ],
                                );
                              },
                            ),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      AppColors.heroGradient
                                          .createShader(bounds),
                                  child: const Icon(
                                    Iconsax.scan,
                                    size: 72,
                                    color: Colors.white,
                                  ),
                                ),
                                const Gap(16),
                                Text(
                                  'وجه الكاميرا نحو النص',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (scanning)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    LoadingAnimationWidget.staggeredDotsWave(
                                      color: AppColors.primary,
                                      size: 50,
                                    ),
                                    const Gap(16),
                                    Text(
                                      'جاري استخراج النص...',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).scale(
                begin: const Offset(0.95, 0.95)),

            // Selection hint & actions
            Obx(() {
              if (!ocrCtrl.hasBlocks || ocrCtrl.isScanning.value) {
                return const SizedBox.shrink();
              }
              final totalBlocks = ocrCtrl.recognizedBlocks.length;
              final selectedCount = ocrCtrl.selectedBlockIndices.length;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Icon(Iconsax.finger_scan,
                        size: 16,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        selectedCount == 0
                            ? 'اضغط على النص في الصورة لتحديد جزء للترجمة'
                            : 'تم تحديد $selectedCount من $totalBlocks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: selectedCount == 0
                              ? (isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textSecondary)
                              : AppColors.primary,
                          fontWeight: selectedCount > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (selectedCount > 0) ...[
                      _buildSmallAction(
                        label: 'ترجمة المحدد',
                        icon: Iconsax.translate,
                        color: AppColors.teal,
                        onTap: ocrCtrl.translateSelected,
                      ),
                      const Gap(6),
                      _buildSmallAction(
                        label: 'إلغاء',
                        icon: Iconsax.close_circle,
                        color: AppColors.textSecondary,
                        onTap: ocrCtrl.clearSelection,
                      ),
                    ] else if (totalBlocks > 1)
                      _buildSmallAction(
                        label: 'تحديد الكل',
                        icon: Iconsax.tick_square,
                        color: AppColors.primary,
                        onTap: ocrCtrl.selectAllBlocks,
                      ),
                  ],
                ),
              );
            }),

            // Bottom action bar: Settings | Camera | Gallery
            _buildOcrBottomBar(theme, isDark, ocrCtrl),

            const Gap(8),
          ],
        ),

        // Draggable results bottom sheet
        _buildOcrResultsSheet(theme, isDark, ocrCtrl),
      ],
    );
  }

  /// Bottom bar with settings, camera capture, and gallery buttons
  Widget _buildOcrBottomBar(
      ThemeData theme, bool isDark, OcrReaderController ocrCtrl) {
    return Obx(() {
      final busy = ocrCtrl.isScanning.value || ocrCtrl.isTranslating.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Settings button (placeholder)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.8)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: busy ? null : () => _showOcrSettingsSheet(theme, isDark, ocrCtrl),
                  borderRadius: BorderRadius.circular(26),
                  child: Icon(
                    Iconsax.setting_2,
                    size: 24,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Camera capture button (big center)
            GestureDetector(
              onTap: busy ? null : ocrCtrl.captureAndScan,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white70 : Colors.grey.shade400,
                    width: 4,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: busy ? null : AppColors.heroGradient,
                    color: busy
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.camera,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Gallery button
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.8)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: busy ? null : ocrCtrl.pickFromGallery,
                  borderRadius: BorderRadius.circular(26),
                  child: Icon(
                    Iconsax.gallery,
                    size: 24,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  /// OCR settings bottom sheet
  void _showOcrSettingsSheet(
      ThemeData theme, bool isDark, OcrReaderController ocrCtrl) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            Text(
              'إعدادات قارئ النصوص',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(20),
            ListTile(
              leading: const Icon(Iconsax.info_circle, color: AppColors.primary),
              title: const Text('حول قارئ النصوص'),
              subtitle: const Text(
                'التقط صورة أو اختر من المعرض لاستخراج النص وترجمته تلقائياً',
              ),
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }

  /// Draggable bottom sheet for OCR results
  Widget _buildOcrResultsSheet(
      ThemeData theme, bool isDark, OcrReaderController ocrCtrl) {
    return Obx(() {
      final hasResults = ocrCtrl.scannedText.value.isNotEmpty ||
          ocrCtrl.isTranslating.value;
      final displayText = ocrCtrl.hasSelection
          ? ocrCtrl.selectedText
          : ocrCtrl.scannedText.value;

      return NotificationListener<DraggableScrollableNotification>(
        onNotification: (_) => true,
        child: DraggableScrollableSheet(
          initialChildSize: hasResults ? 0.45 : 0.12,
          minChildSize: 0.10,
          maxChildSize: 0.85,
          snap: true,
          snapSizes: const [0.12, 0.45, 0.85],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Drag handle
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // "اسحب لرؤية النتائج" hint
                  if (!hasResults)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
                            size: 16,
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary,
                          ),
                          const Gap(4),
                          Text(
                            'اسحب لرؤية النتائج',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: !hasResults
                        ? Column(
                            children: [
                              const Gap(32),
                              Icon(
                                Iconsax.text,
                                size: 48,
                                color: isDark
                                    ? AppColors.textOnDarkSecondary
                                        .withValues(alpha: 0.4)
                                    : AppColors.textLight,
                              ),
                              const Gap(12),
                              Text(
                                'سيظهر النص المستخرج هنا بعد التقاط الصورة',
                                textAlign: TextAlign.center,
                                style:
                                    theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.textOnDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const Gap(32),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Iconsax.document_text,
                                          size: 18,
                                          color: AppColors.primary),
                                      const Gap(6),
                                      Text(
                                        ocrCtrl.hasSelection
                                            ? 'النص المحدد:'
                                            : 'النص المستخرج:',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(Iconsax.close_circle,
                                        size: 20,
                                        color: AppColors.textLight),
                                    onPressed: ocrCtrl.clearText,
                                    tooltip: 'مسح النص',
                                  ),
                                ],
                              ),
                              const Gap(4),
                              SelectableText(
                                displayText,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Divider(
                                  height: 20,
                                  color: isDark
                                      ? AppColors.dividerDark
                                      : AppColors.divider),
                              Row(
                                children: [
                                  const Icon(Iconsax.translate,
                                      size: 18, color: AppColors.teal),
                                  const Gap(6),
                                  Text(
                                    'الترجمة:',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(4),
                              if (ocrCtrl.isTranslating.value)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  child: LoadingAnimationWidget
                                      .staggeredDotsWave(
                                    color: AppColors.teal,
                                    size: 30,
                                  ),
                                )
                              else
                                SelectableText(
                                  ocrCtrl.translatedText.value,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              const Gap(16),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  /// Build tappable overlay widgets for each recognized text block.
  List<Widget> _buildBlockOverlays(
    Size widgetSize,
    Size imgSize,
    List<dynamic> blocks,
    Set<int> selected,
    OcrReaderController ocrCtrl,
  ) {
    // Calculate how the image fits inside the widget with BoxFit.contain
    final scaleX = widgetSize.width / imgSize.width;
    final scaleY = widgetSize.height / imgSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final renderedW = imgSize.width * scale;
    final renderedH = imgSize.height * scale;
    final offsetX = (widgetSize.width - renderedW) / 2;
    final offsetY = (widgetSize.height - renderedH) / 2;

    final overlays = <Widget>[];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final bbox = block.boundingBox;
      final isSelected = selected.contains(i);

      final left = offsetX + bbox.left * scale;
      final top = offsetY + bbox.top * scale;
      final width = bbox.width * scale;
      final height = bbox.height * scale;

      overlays.add(
        Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: GestureDetector(
            onTap: () => ocrCtrl.toggleBlockSelection(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.4),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: isSelected
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    return overlays;
  }

  Widget _buildSmallAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrLanguageSelector(ThemeData theme, bool isDark, OcrReaderController ocrCtrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => LanguageSelector(
                  language: ocrCtrl.sourceLanguage.value,
                  onTap: ocrCtrl.goToLanguageSelection,
                ),
              ),
            ),
            const Gap(8),
            GestureDetector(
              onTap: ocrCtrl.swapLanguages,
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
                child: const Icon(
                  Iconsax.arrow_swap_horizontal,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const Gap(8),
            Expanded(
              child: Obx(
                () => LanguageSelector(
                  language: ocrCtrl.targetLanguage.value,
                  onTap: ocrCtrl.goToLanguageSelection,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  void _showOcrInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surface,
        title: Row(
          children: [
            const Icon(Iconsax.scan, color: AppColors.primary),
            const Gap(10),
            const Text('قارئ اللافتات'),
          ],
        ),
        content: const Text(
          'هذه الميزة تتيح لك قراءة النصوص من اللافتات والإعلانات وترجمتها.\n\n'
          'التقط صورة أو اختر من المعرض لاستخراج النص وترجمته تلقائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
