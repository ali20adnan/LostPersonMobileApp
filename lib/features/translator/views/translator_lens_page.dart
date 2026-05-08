import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../ocr_reader/controllers/ocr_reader_controller.dart';
import '../controllers/translator_controller.dart';
import '../widgets/lens_overlay.dart';

/// Google-Lens-style OCR result page (Image 6).
/// - Toggle between original and translated overlays.
/// - Tap "Send to translator" to push the extracted text into the
///   main translator text page.
class TranslatorLensPage extends StatefulWidget {
  const TranslatorLensPage({super.key});

  @override
  State<TranslatorLensPage> createState() => _TranslatorLensPageState();
}

class _TranslatorLensPageState extends State<TranslatorLensPage> {
  late final OcrReaderController ocrCtrl;
  late final TranslatorController translatorCtrl;

  @override
  void initState() {
    super.initState();
    ocrCtrl = Get.find<OcrReaderController>();
    translatorCtrl = Get.find<TranslatorController>();
    ocrCtrl.lensMode.value = true;
    // Kick off per-block translation as soon as the page mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ocrCtrl.translateAllBlocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'عدسة Google',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowRight()),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Gap(8),
              _buildModeToggle(),
              const Gap(12),
              Expanded(child: _buildImagePreview()),
              const Gap(8),
              _buildLanguagesRow(isDark),
              const Gap(12),
              _buildSendButton(),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Obx(
          () => Row(
            children: [
              _buildToggleTab(
                label: 'محتوى مترجم',
                selected: ocrCtrl.lensMode.value,
                onTap: () => ocrCtrl.setLensMode(true),
              ),
              _buildToggleTab(
                label: 'النص الأصلي',
                selected: !ocrCtrl.lensMode.value,
                onTap: () => ocrCtrl.setLensMode(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Obx(
          () => LensOverlay(
            imagePath: ocrCtrl.capturedImagePath.value,
            originalImageSize: ocrCtrl.imageSize.value,
            blocks: ocrCtrl.recognizedBlocks.toList(),
            translations: ocrCtrl.blockTranslations.toList(),
            showTranslations: ocrCtrl.lensMode.value,
            isLoading: ocrCtrl.isTranslatingBlocks.value,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguagesRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _buildLanguageChip(
                ocrCtrl.sourceLanguage.value.nameAr,
              ),
            ),
          ),
          const Gap(12),
          GestureDetector(
            onTap: () {
              ocrCtrl.swapLanguages();
              ocrCtrl.translateAllBlocks();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.arrowsLeftRight(),
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Obx(
              () => _buildLanguageChip(
                ocrCtrl.targetLanguage.value.nameAr,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final hasBlocks = ocrCtrl.recognizedBlocks.isNotEmpty;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasBlocks
                ? () => translatorCtrl
                    .sendOcrTextToTranslator(ocrCtrl.combinedScannedText)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              disabledBackgroundColor:
                  AppColors.accent.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(PhosphorIcons.arrowRight()),
            label: const Text(
              'إرسال إلى المترجم',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        );
      }),
    );
  }
}
