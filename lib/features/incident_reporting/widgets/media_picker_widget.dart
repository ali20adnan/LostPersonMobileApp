import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

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
                  GestureDetector(
                    onTap: () => _showMediaPreview(context, file, isVideo),
                    child: Container(
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

  Future<void> _showMediaPreview(
    BuildContext context,
    XFile file,
    bool isVideo,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => _LocalMediaPreviewDialog(
        file: file,
        isVideo: isVideo,
      ),
    );
  }
}

class _LocalMediaPreviewDialog extends StatelessWidget {
  final XFile file;
  final bool isVideo;

  const _LocalMediaPreviewDialog({
    required this.file,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              file.name.isNotEmpty ? file.name : 'معاينة الملف',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isVideo
                  ? SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: _LocalVideoPreviewPlayer(filePath: file.path),
                    )
                  : InteractiveViewer(
                      child: Image.file(
                        File(file.path),
                        fit: BoxFit.contain,
                        height: 380,
                        width: double.infinity,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalVideoPreviewPlayer extends StatefulWidget {
  final String filePath;

  const _LocalVideoPreviewPlayer({required this.filePath});

  @override
  State<_LocalVideoPreviewPlayer> createState() => _LocalVideoPreviewPlayerState();
}

class _LocalVideoPreviewPlayerState extends State<_LocalVideoPreviewPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath));
    _initializeFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !_controller.value.isInitialized) {
          return Center(
            child: Icon(PhosphorIcons.videoCamera(), size: 42, color: AppColors.primary),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.black26,
                child: InkWell(
                  onTap: () async {
                    if (_controller.value.isPlaying) {
                      await _controller.pause();
                    } else {
                      await _controller.play();
                    }

                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: Center(
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              left: 8,
              bottom: 8,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.black38,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
