import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/themes/app_colors.dart';

/// Widget for picking and displaying media files (photos/videos)
class MediaPickerWidget extends StatelessWidget {
  final List<XFile> mediaFiles;
  final VoidCallback onPickImage;
  final VoidCallback onTakePhoto;
  final VoidCallback? onPickVideo;
  final Function(int) onRemoveFile;

  const MediaPickerWidget({
    super.key,
    required this.mediaFiles,
    required this.onPickImage,
    required this.onTakePhoto,
    this.onPickVideo,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyStateLabel = onPickVideo != null
        ? 'لم يتم إضافة صور أو فيديو بعد'
        : 'لم يتم إضافة صور بعد';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIcons.camera(),
                label: 'التقاط صورة',
                onPressed: onTakePhoto,
                isDark: isDark,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildActionButton(
                icon: PhosphorIcons.images(),
                label: 'اختيار صورة',
                onPressed: onPickImage,
                isDark: isDark,
              ),
            ),
          ],
        ),

        if (onPickVideo != null) ...[
          const Gap(8),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              icon: PhosphorIcons.videoCamera(),
              label: 'اختيار فيديو',
              onPressed: onPickVideo!,
              isDark: isDark,
            ),
          ),
        ],

        // Media files grid
        if (mediaFiles.isNotEmpty) ...[
          const Gap(16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: mediaFiles.length,
            itemBuilder: (context, index) {
              final file = mediaFiles[index];
              final isVideo = file.path.toLowerCase().endsWith('.mp4') ||
                  file.path.toLowerCase().endsWith('.mov');

              return Stack(
                children: [
                  // Media preview
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.cardBorderDark
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: isVideo
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: AppColors.heroGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIcons.play(),
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    PhosphorIcons.image(),
                                    color: AppColors.error,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // Delete button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemoveFile(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          PhosphorIcons.xCircle(),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Video indicator
                  if (isVideo)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIcons.videoCamera(),
                              color: Colors.white,
                              size: 12,
                            ),
                            Gap(2),
                            Text(
                              'فيديو',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],

        // Empty state
        if (mediaFiles.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.5)
                  : AppColors.surfaceSunken.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.cardBorderDark
                    : AppColors.cardBorder,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      PhosphorIcons.cameraPlus(),
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    emptyStateLabel,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
