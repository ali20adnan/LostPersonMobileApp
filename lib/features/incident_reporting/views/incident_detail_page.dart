import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:video_player/video_player.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/constants/incident_constants.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../data/models/incident_model.dart';
import '../controllers/incident_detail_controller.dart';

class IncidentDetailPage extends GetView<IncidentDetailController> {
  const IncidentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoading();
        }

        final report = controller.report.value;
        if (report == null) {
          return _buildError(isDark);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refreshReport,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(report, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(report, isDark),
                      const Gap(12),
                      if (report.description != null &&
                          report.description!.isNotEmpty) ...[
                        _buildDescriptionSection(report, isDark),
                        const Gap(12),
                      ],
                      if (report.photos.isNotEmpty) ...[
                        _buildPhotosGallery(report, isDark),
                        const Gap(12),
                      ],
                      _buildDetailsSection(report, isDark),
                      const Gap(12),
                      _buildLocationSection(report, isDark),
                      const Gap(12),
                      _buildPeopleSection(report, isDark),
                      const Gap(32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: AppColors.primary,
        size: 40,
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warningCircle(), size: 64, color: AppColors.error),
          const Gap(16),
          Text(
            'لم يتم العثور على البلاغ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          TextButton.icon(
            onPressed: controller.loadReport,
            icon: Icon(PhosphorIcons.arrowsClockwise()),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Report report, bool isDark) {
    final type = ReportType.fromString(report.type);
    final severity = ReportSeverity.fromString(report.severity ?? 'medium');

    return SliverAppBar(
      pinned: true,
      backgroundColor: severity.color,
      foregroundColor: Colors.white,
      title: Text(
        report.displayTitle,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [severity.color, severity.color.withValues(alpha: 0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Icon(type.icon, size: 48, color: Colors.white38),
            ),
          ),
        ),
      ),
      expandedHeight: 140,
    );
  }

  Widget _buildStatusHeader(Report report, bool isDark) {
    final type = ReportType.fromString(report.type);
    final severity = ReportSeverity.fromString(report.severity ?? 'medium');
    final status = ReportStatus.fromApiString(report.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: isDark ? null : AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Type + Status row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      severity.color,
                      severity.color.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.icon, size: 22, color: Colors.white),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayNameAr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      _formatDate(report.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: status.color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  status.displayNameAr,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          // Severity bar
          Row(
            children: [
              Icon(PhosphorIcons.warning(), size: 16, color: severity.color),
              const Gap(6),
              Text(
                'الخطورة:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const Gap(8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severity.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  severity.displayNameAr,
                  style: TextStyle(
                    color: severity.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildDescriptionSection(Report report, bool isDark) {
    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.fileText(),
      title: 'الوصف',
      children: [
        Text(
          report.description ?? '',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosGallery(Report report, bool isDark) {
    final hasVideo = report.photos.any((photo) => photo.attachment.isVideo);

    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.images(),
      title: 'الملفات المرفقة (${report.photos.length})',
      children: [
        SizedBox(
          height: hasVideo ? 190 : 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: report.photos.length,
            separatorBuilder: (context, index) => const Gap(8),
            itemBuilder: (context, index) {
              final photo = report.photos[index];
              final photoUrl = photo.displayUrl;

              if (photo.attachment.isVideo) {
                return SizedBox(
                  width: 220,
                  child: photoUrl != null
                      ? _IncidentVideoCard(
                          videoUrl: photoUrl,
                          fileName: photo.attachment.originalName,
                          onPreview: () => _showRemoteMediaPreview(
                            context,
                            title: photo.attachment.originalName,
                            url: photoUrl,
                            isVideo: true,
                          ),
                        )
                      : _videoPlaceholder(photo.attachment.originalName),
                );
              }

              return GestureDetector(
                onTap: photoUrl == null
                    ? null
                    : () => _showRemoteMediaPreview(
                          context,
                          title: photo.attachment.originalName,
                          url: photoUrl,
                          isVideo: false,
                        ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(Report report, bool isDark) {
    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.info(),
      title: 'تفاصيل البلاغ',
      children: [
        _buildInfoRow(isDark, 'رقم البلاغ', '#${report.id}'),
        _buildInfoRow(
            isDark, 'تاريخ الإنشاء', _formatDate(report.createdAt)),
        _buildInfoRow(
            isDark, 'آخر تحديث', _formatDate(report.updatedAt)),
        if (report.reviewedAt != null)
          _buildInfoRow(
              isDark, 'تاريخ المراجعة', _formatDate(report.reviewedAt!)),
      ],
    );
  }

  Widget _buildLocationSection(Report report, bool isDark) {
    final hasLocation = report.addressLine != null ||
        report.latitude != null;

    if (!hasLocation) return const SizedBox.shrink();

    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.mapPin(),
      title: 'الموقع',
      children: [
        if (report.addressLine != null && report.addressLine!.isNotEmpty)
          _buildInfoRow(isDark, 'العنوان', report.addressLine!),
        if (report.latitude != null && report.longitude != null) ...[
          _buildInfoRow(
            isDark,
            'الإحداثيات',
            '${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
          ),
          const Gap(8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openMapsDirections(
                lat: report.latitude,
                lng: report.longitude,
              ),
              icon: Icon(PhosphorIcons.navigationArrow(), size: 18),
              label: const Text('فتح الاتجاهات في خرائط Google'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPeopleSection(Report report, bool isDark) {
    final hasCreator = report.creator != null;
    final hasReviewer = report.reviewer != null;

    if (!hasCreator && !hasReviewer) return const SizedBox.shrink();

    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.users(),
      title: 'الأشخاص',
      children: [
        if (hasCreator) ...[
          _buildPersonRow(
            isDark,
            'المُبلغ',
            report.creator!.fullName,
            report.creator!.role,
          ),
        ],
        if (hasReviewer) ...[
          if (hasCreator) const Gap(8),
          _buildPersonRow(
            isDark,
            'المُراجع',
            report.reviewer!.fullName,
            report.reviewer!.role,
          ),
        ],
      ],
    );
  }

  // ── Shared UI helpers ──────────────────────────────────────────

  Widget _buildSection({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: isDark ? null : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const Gap(10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(12),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildInfoRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const Gap(8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow(
      bool isDark, String role, String name, String? userRole) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (userRole != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              userRole,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(date);
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: AppColors.surfaceSunken,
      child: Icon(PhosphorIcons.images(), color: AppColors.textLight, size: 32),
    );
  }

  Widget _videoPlaceholder(String fileName) {
    return Container(
      width: 220,
      height: 180,
      color: AppColors.surfaceSunken,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.videoCamera(), color: AppColors.primary, size: 28),
          const Gap(8),
          Text(
            fileName.isNotEmpty ? fileName : 'ملف فيديو',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemoteMediaPreview(
    BuildContext context, {
    required String title,
    required String url,
    required bool isVideo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => _RemoteMediaPreviewDialog(
        title: title,
        url: url,
        isVideo: isVideo,
      ),
    );
  }
}

class _IncidentVideoCard extends StatefulWidget {
  final String videoUrl;
  final String fileName;
  final VoidCallback onPreview;

  const _IncidentVideoCard({
    required this.videoUrl,
    required this.fileName,
    required this.onPreview,
  });

  @override
  State<_IncidentVideoCard> createState() => _IncidentVideoCardState();
}

class _IncidentVideoCardState extends State<_IncidentVideoCard> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeFuture = _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: AppColors.primary,
                size: 28,
              ),
            ),
          );
        }

        if (snapshot.hasError || !controller.value.isInitialized) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.videoCamera(), color: AppColors.primary, size: 30),
                const Gap(8),
                Text(
                  widget.fileName.isNotEmpty ? widget.fileName : 'فيديو مرفق',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.black26,
                  child: InkWell(
                    onTap: _togglePlayback,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.value.isPlaying
                              ? PhosphorIcons.pause()
                              : PhosphorIcons.play(),
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  onPressed: widget.onPreview,
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                left: 8,
                bottom: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                    colors: VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.black38,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RemoteMediaPreviewDialog extends StatelessWidget {
  final String title;
  final String url;
  final bool isVideo;

  const _RemoteMediaPreviewDialog({
    required this.title,
    required this.url,
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
              title.isNotEmpty ? title : 'معاينة الملف',
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
                      height: 320,
                      width: double.infinity,
                      child: _RemoteVideoPreviewPlayer(videoUrl: url),
                    )
                  : InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        height: 420,
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

class _RemoteVideoPreviewPlayer extends StatefulWidget {
  final String videoUrl;

  const _RemoteVideoPreviewPlayer({required this.videoUrl});

  @override
  State<_RemoteVideoPreviewPlayer> createState() => _RemoteVideoPreviewPlayerState();
}

class _RemoteVideoPreviewPlayerState extends State<_RemoteVideoPreviewPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
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
