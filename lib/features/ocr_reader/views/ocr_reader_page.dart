import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/widgets/shared/motion/animated_appear.dart';
import '../controllers/ocr_reader_controller.dart';

class OcrReaderPage extends GetView<OcrReaderController> {
  const OcrReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'قارئ النصوص',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.info()),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'معلومات',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Language selector
            AnimatedAppear(child: _buildLanguageBar(theme)),

            const SizedBox(height: 12),

            // Image preview / empty state
            Expanded(
              flex: 3,
              child: AnimatedAppear(
                delay: const Duration(milliseconds: 80),
                child: _buildImagePreview(theme),
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            AnimatedAppear(
              delay: const Duration(milliseconds: 160),
              child: _buildActionButtons(theme),
            ),

            const SizedBox(height: 12),

            // Scanned text + translation display
            Expanded(
              flex: 2,
              child: AnimatedAppear(
                delay: const Duration(milliseconds: 240),
                child: _buildTextDisplay(theme),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBar(ThemeData theme) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.sourceLanguage.value.nameAr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.arrowsLeftRight(), color: theme.colorScheme.primary),
                onPressed: controller.swapLanguages,
                tooltip: 'تبديل اللغات',
              ),
              Expanded(
                child: Text(
                  controller.targetLanguage.value.nameAr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Obx(() {
      final imagePath = controller.capturedImagePath.value;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              if (imagePath.isNotEmpty)
                Positioned.fill(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.scan(),
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'التقط صورة أو اختر من المعرض',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              if (controller.isScanning.value)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري استخراج النص...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
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
    });
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Obx(() {
      final busy = controller.isScanning.value || controller.isTranslating.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: busy ? null : controller.captureAndScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.5),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(PhosphorIcons.camera(), size: 22),
                  label: Text(
                    'التقاط صورة',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: busy ? null : controller.pickFromGallery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    disabledBackgroundColor:
                        theme.colorScheme.secondary.withValues(alpha: 0.5),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(PhosphorIcons.images(), size: 22),
                  label: Text(
                    'من المعرض',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTextDisplay(ThemeData theme) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: controller.scannedText.value.isEmpty && !controller.isTranslating.value
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.textT(),
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'النص المستخرج سيظهر هنا',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'النص المستخرج:',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(PhosphorIcons.x(), size: 20),
                            onPressed: controller.clearText,
                            tooltip: 'مسح النص',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        controller.scannedText.value,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Divider(height: 24),
                      Text(
                        'الترجمة:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (controller.isTranslating.value)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        SelectableText(
                          controller.translatedText.value,
                          style: theme.textTheme.bodyLarge,
                        ),
                    ],
                  ),
                ),
        ));
  }

  void _showInfoDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('قارئ النصوص'),
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
