import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../app/themes/app_colors.dart';

/// Renders the captured image with one overlay per recognized text block.
/// Each overlay shows either the original block text or its translation,
/// chosen by [showTranslations]. While translations are still loading,
/// translated overlays show a small loading hint.
class LensOverlay extends StatelessWidget {
  final String imagePath;
  final Size originalImageSize;
  final List<TextBlock> blocks;
  final List<String> translations;
  final bool showTranslations;
  final bool isLoading;

  const LensOverlay({
    super.key,
    required this.imagePath,
    required this.originalImageSize,
    required this.blocks,
    required this.translations,
    required this.showTranslations,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            if (originalImageSize != Size.zero && blocks.isNotEmpty)
              ..._buildBlockOverlays(constraints.biggest),
          ],
        );
      },
    );
  }

  List<Widget> _buildBlockOverlays(Size widgetSize) {
    final scaleX = widgetSize.width / originalImageSize.width;
    final scaleY = widgetSize.height / originalImageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final renderedW = originalImageSize.width * scale;
    final renderedH = originalImageSize.height * scale;
    final offsetX = (widgetSize.width - renderedW) / 2;
    final offsetY = (widgetSize.height - renderedH) / 2;

    final overlays = <Widget>[];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final bbox = block.boundingBox;
      final left = offsetX + bbox.left * scale;
      final top = offsetY + bbox.top * scale;
      final width = bbox.width * scale;
      final height = bbox.height * scale;

      final translated = i < translations.length ? translations[i] : '';
      final original = block.text;
      final hasTranslation = translated.trim().isNotEmpty;
      final text = showTranslations
          ? (hasTranslation ? translated : original)
          : original;

      overlays.add(
        Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 0.6,
              ),
            ),
            child: showTranslations && isLoading && !hasTranslation
                ? const Center(
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.4),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
          ),
        ),
      );
    }

    return overlays;
  }
}
