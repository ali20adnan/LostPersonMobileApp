import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
          'قارئ اللافتات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'معلومات',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info banner
            _buildInfoBanner(theme),

            const SizedBox(height: 16),

            // Camera preview area (simulated)
            Expanded(
              flex: 3,
              child: _buildCameraPreview(theme),
            ),

            const SizedBox(height: 16),

            // Scan button
            _buildScanButton(theme),

            const SizedBox(height: 16),

            // Scanned text display
            Expanded(
              flex: 2,
              child: _buildTextDisplay(theme),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            color: theme.colorScheme.primary,
          ),
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
    );
  }

  Widget _buildCameraPreview(ThemeData theme) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Simulated camera view
              Center(
                child: controller.isScanning.value
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري المسح...',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'معاينة الكاميرا',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '(واجهة تجريبية)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
              ),

              // Scanning overlay
              if (controller.isScanning.value)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ScanningOverlayPainter(),
                  ),
                ),
            ],
          ),
        ));
  }

  Widget _buildScanButton(ThemeData theme) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 56,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.isScanning.value
                ? null
                : controller.startScanning,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor:
                  theme.colorScheme.primary.withOpacity(0.5),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              controller.isScanning.value
                  ? Icons.hourglass_empty
                  : Icons.document_scanner,
              size: 24,
            ),
            label: Text(
              controller.isScanning.value ? 'جاري المسح...' : 'مسح اللافتة',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
  }

  Widget _buildTextDisplay(ThemeData theme) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: controller.scannedText.value.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'النص الممسوح سيظهر هنا',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                            'النص الممسوح:',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
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

class ScanningOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw scanning frame
    final rect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.3,
      size.width * 0.8,
      size.height * 0.4,
    );

    canvas.drawRect(rect, paint);

    // Draw corner marks
    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = 20.0;

    // Top-left
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + cornerLength),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right - cornerLength, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - cornerLength, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
