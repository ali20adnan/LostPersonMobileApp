import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/audio_visualizer.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/record_button.dart';
import '../../ocr_reader/controllers/ocr_reader_controller.dart';
import '../controllers/translator_controller.dart';
import '../widgets/message_bubble.dart';

/// Merged page combining Voice Translator and OCR Text Reader
/// with a SegmentedButton switcher for clean navigation.
class TranslatorToolsPage extends GetView<TranslatorController> {
  const TranslatorToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(() => Text(
              controller.toolMode.value == 0
                  ? 'مترجم الحرم الفوري'
                  : 'قارئ اللافتات',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
        centerTitle: true,
        elevation: 0,
        actions: [
          Obx(() {
            if (controller.toolMode.value == 1) {
              return IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showOcrInfoDialog(context),
                tooltip: 'معلومات',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildModeSwitcher(theme),
            Expanded(
              child: Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: controller.toolMode.value == 0
                        ? KeyedSubtree(
                            key: const ValueKey(0),
                            child: _buildTranslatorContent(theme),
                          )
                        : KeyedSubtree(
                            key: const ValueKey(1),
                            child: _buildOcrContent(theme),
                          ),
                  )),
            ),
          ],
        ),
      ),
      floatingActionButton: Obx(() => controller.toolMode.value == 0
          ? _buildTranslatorFabs()
          : const SizedBox.shrink()),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // ── Mode Switcher ─────────────────────────────────────────────

  Widget _buildModeSwitcher(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Obx(() => SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('مترجم صوتي'),
                icon: Icon(Icons.mic, size: 18),
              ),
              ButtonSegment(
                value: 1,
                label: Text('قارئ نصوص'),
                icon: Icon(Icons.document_scanner_outlined, size: 18),
              ),
            ],
            selected: {controller.toolMode.value},
            onSelectionChanged: (selected) {
              if (controller.isRecording.value) {
                Get.snackbar(
                  'تنبيه',
                  'يجب إيقاف التسجيل أولاً',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.withValues(alpha: 0.8),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                );
                return;
              }
              controller.toolMode.value = selected.first;
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          )),
    );
  }

  // ── Voice Translator Content ──────────────────────────────────

  Widget _buildTranslatorContent(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Language selector with swap button
        _buildLanguageSelector(theme),

        const SizedBox(height: 16),

        // Messages display
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Obx(
                  () => controller.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ابدأ الحديث لرؤية الترجمة',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
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

        const SizedBox(height: 16),

        // Record button
        Obx(
          () => RecordButton(
            isRecording: controller.isRecording.value,
            isLoading: controller.isInitializing.value,
            onPressed: controller.toggleRecording,
            size: 72,
          ),
        ),

        const SizedBox(height: 8),

        // Recording hint
        Obx(
          () => Text(
            controller.isRecording.value ? 'اضغط للتوقف' : 'اضغط للبدء',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLanguageSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(width: 12),
          InkWell(
            onTap: controller.swapLanguages,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.swap_horiz,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
    );
  }

  Widget _buildTranslatorFabs() {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.currentTranslation.value.isNotEmpty)
            FloatingActionButton(
              heroTag: 'speak',
              onPressed: controller.speakTranslation,
              child: const Icon(Icons.volume_up),
            ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'history',
            onPressed: controller.goToHistory,
            child: const Icon(Icons.history),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'settings',
            onPressed: controller.goToSettings,
            child: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  // ── OCR Text Reader Content ───────────────────────────────────

  Widget _buildOcrContent(ThemeData theme) {
    final ocrCtrl = Get.find<OcrReaderController>();

    return Column(
      children: [
        const SizedBox(height: 8),

        // Info banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.camera_alt_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'وجه الكاميرا نحو اللافتة لقراءة النص',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Camera preview
        Expanded(
          flex: 3,
          child: Obx(() => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ocrCtrl.isScanning.value
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'جاري المسح...',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.document_scanner_outlined,
                                  size: 64,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'معاينة الكاميرا',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '(واجهة تجريبية)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (ocrCtrl.isScanning.value)
                      Positioned.fill(
                        child:
                            CustomPaint(painter: _ScanningOverlayPainter()),
                      ),
                  ],
                ),
              )),
        ),

        const SizedBox(height: 12),

        // Scan button
        Obx(() => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    ocrCtrl.isScanning.value ? null : ocrCtrl.startScanning,
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
                icon: Icon(
                  ocrCtrl.isScanning.value
                      ? Icons.hourglass_empty
                      : Icons.document_scanner,
                  size: 22,
                ),
                label: Text(
                  ocrCtrl.isScanning.value ? 'جاري المسح...' : 'مسح اللافتة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )),

        const SizedBox(height: 12),

        // Scanned text display
        Expanded(
          flex: 2,
          child: Obx(() => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: ocrCtrl.scannedText.value.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.text_fields,
                              size: 40,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'النص الممسوح سيظهر هنا',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'النص الممسوح:',
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: ocrCtrl.clearText,
                                  tooltip: 'مسح النص',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              ocrCtrl.scannedText.value,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const Divider(height: 20),
                            Text(
                              'الترجمة:',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              ocrCtrl.translatedText.value,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
              )),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  void _showOcrInfoDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('قارئ اللافتات'),
        content: const Text(
          'هذه الميزة تتيح لك قراءة النصوص من اللافتات والإعلانات في الحرم.\n\n'
          'ملاحظة: هذه واجهة تجريبية فقط ولا تعمل بشكل فعلي حالياً.',
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

/// Scanning overlay with corner markers for OCR camera view
class _ScanningOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.3,
      size.width * 0.8,
      size.height * 0.4,
    );
    canvas.drawRect(rect, paint);

    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 20.0;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left + cornerLength, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left, rect.top + cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right - cornerLength, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerLength, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left, rect.bottom - cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right - cornerLength, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
