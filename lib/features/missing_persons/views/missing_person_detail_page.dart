import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/maps_launcher.dart';
import '../../../core/widgets/shared/motion/animated_appear.dart';
import '../../../data/models/missing_person_report_model.dart';
import '../controllers/missing_person_detail_controller.dart';

class MissingPersonDetailPage extends GetView<MissingPersonDetailController> {
  const MissingPersonDetailPage({super.key});

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
                      AnimatedAppear(
                        child: _buildStatusHeader(report, isDark),
                      ),
                      if (report.isFound) ...[
                        const Gap(12),
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 60),
                          child: _buildFoundInfoSection(report, isDark),
                        ),
                      ],
                      const Gap(16),
                      AnimatedAppear(
                        delay: const Duration(milliseconds: 80),
                        child: _buildPersonInfoSection(report, isDark),
                      ),
                      const Gap(12),
                      if (report.description != null &&
                          report.description!.isNotEmpty) ...[
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 160),
                          child: _buildDescriptionSection(report, isDark),
                        ),
                        const Gap(12),
                      ],
                      AnimatedAppear(
                        delay: const Duration(milliseconds: 240),
                        child: _buildPhysicalSection(report, isDark),
                      ),
                      const Gap(12),
                      AnimatedAppear(
                        delay: const Duration(milliseconds: 320),
                        child: _buildLocationSection(report, isDark),
                      ),
                      const Gap(12),
                      AnimatedAppear(
                        delay: const Duration(milliseconds: 400),
                        child: _buildReporterSection(report, isDark),
                      ),
                      const Gap(24),
                      if (report.isMissing)
                        AnimatedAppear(
                          delay: const Duration(milliseconds: 480),
                          child: _buildActionButtons(report, isDark),
                        ),
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
            'لم يتم العثور على البيانات',
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

  Widget _buildSliverAppBar(MissingPersonReport report, bool isDark) {
    final photoUrl = report.primaryPhotoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasPhoto ? 300 : 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'mp-photo-${report.id}',
                    child: Image.network(
                      _resolvePhotoUrl(photoUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary,
                        child: Icon(PhosphorIcons.user(),
                            size: 80, color: Colors.white38),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: const BoxDecoration(color: AppColors.primary),
              ),
        title: Text(
          report.fullName ?? 'غير معروف',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildStatusHeader(MissingPersonReport report, bool isDark) {
    final isMissing = report.isMissing;
    final statusColor = isMissing ? AppColors.error : AppColors.teal;
    final statusText = isMissing ? 'مفقود' : 'تم العثور عليه';
    final statusIcon = isMissing ? PhosphorIcons.magnifyingGlass() : PhosphorIcons.checkCircle();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Gap(4),
                Text(
                  report.isFound && report.foundDate != null
                      ? 'تاريخ العثور: ${report.foundDate}'
                      : 'تاريخ الفقدان: ${report.missingDate}',
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
          Text(
            _relativeTime(report.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildFoundInfoSection(MissingPersonReport report, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.checkCircle(),
                    size: 18, color: AppColors.teal),
              ),
              const Gap(10),
              Text(
                'معلومات العثور',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(12),
          if (report.foundDate != null)
            _buildInfoRow(isDark, 'تاريخ العثور', report.foundDate!),
          if (report.foundLocation != null && report.foundLocation!.isNotEmpty)
            _buildInfoRow(isDark, 'مكان العثور', report.foundLocation!),
          if (report.foundReason != null && report.foundReason!.isNotEmpty)
            _buildInfoRow(isDark, 'سبب العثور', report.foundReason!),
          if (report.foundNotes != null && report.foundNotes!.isNotEmpty)
            _buildInfoRow(isDark, 'ملاحظات', report.foundNotes!),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildPersonInfoSection(MissingPersonReport report, bool isDark) {
    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.user(),
      title: 'معلومات الشخص',
      children: [
        _buildInfoRow(isDark, 'الاسم', report.fullName ?? 'غير معروف'),
        _buildInfoRow(isDark, 'العمر', report.age != null ? '${report.age} سنة' : 'غير محدد'),
        _buildInfoRow(isDark, 'الجنس', _getGenderAr(report.gender)),
      ],
    );
  }

  Widget _buildDescriptionSection(MissingPersonReport report, bool isDark) {
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

  Widget _buildPhysicalSection(MissingPersonReport report, bool isDark) {
    final features = <MapEntry<String, String>>[];

    if (report.height != null) {
      features.add(MapEntry('الطول', '${report.height} سم'));
    }
    if (report.weight != null) {
      features.add(MapEntry('الوزن', '${report.weight} كغ'));
    }
    if (report.hairColor != null && report.hairColor!.isNotEmpty) {
      features.add(MapEntry('لون الشعر', report.hairColor!));
    }
    if (report.eyeColor != null && report.eyeColor!.isNotEmpty) {
      features.add(MapEntry('لون العيون', report.eyeColor!));
    }
    if (report.clothingDescription != null && report.clothingDescription!.isNotEmpty) {
      features.add(MapEntry('الملابس', report.clothingDescription!));
    }
    if (report.distinguishingFeatures != null && report.distinguishingFeatures!.isNotEmpty) {
      features.add(MapEntry('سمات مميزة', report.distinguishingFeatures!));
    }
    if (report.medicalConditions != null && report.medicalConditions!.isNotEmpty) {
      features.add(MapEntry('حالات طبية', report.medicalConditions!));
    }

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.identificationCard(),
      title: 'الأوصاف والسمات',
      children: features.map((e) => _buildInfoRow(isDark, e.key, e.value)).toList(),
    );
  }

  Widget _buildLocationSection(MissingPersonReport report, bool isDark) {
    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.mapPin(),
      title: 'آخر موقع شوهد فيه',
      children: [
        if (report.lastSeenAddress != null && report.lastSeenAddress!.isNotEmpty)
          _buildInfoRow(isDark, 'العنوان', report.lastSeenAddress!),
        if (report.coordinates != null) ...[
          _buildInfoRow(
            isDark,
            'الإحداثيات',
            '${report.coordinates!['latitude']?.toStringAsFixed(5)}, ${report.coordinates!['longitude']?.toStringAsFixed(5)}',
          ),
          const Gap(8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => openMapsDirections(
                lat: report.coordinates!['latitude'],
                lng: report.coordinates!['longitude'],
              ),
              icon: Icon(PhosphorIcons.navigationArrow(), size: 18),
              label: const Text('فتح الاتجاهات في خرائط Google'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReporterSection(MissingPersonReport report, bool isDark) {
    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.phone(),
      title: 'معلومات المُبلغ',
      children: [
        _buildInfoRow(isDark, 'الاسم', report.reporterName),
        _buildInfoRow(isDark, 'الهاتف', report.reporterPhone),
        if (report.reporterRelationship != null &&
            report.reporterRelationship!.isNotEmpty)
          _buildInfoRow(isDark, 'العلاقة', report.reporterRelationship!),
      ],
    );
  }

  Widget _buildActionButtons(MissingPersonReport report, bool isDark) {
    return Column(
      children: [
        // Mark as found button
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.markAsFound,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Directionality(
                        textDirection: TextDirection.ltr,
                        child: Icon(Icons.check_circle, size: 20, color: Colors.white),
                      ),
                      Gap(8),
                      Text(
                        'تم العثور عليه',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
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
            width: 90,
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

  String _getGenderAr(String? gender) {
    if (gender == null) return 'غير محدد';
    switch (gender.toLowerCase()) {
      case 'male':
        return 'ذكر';
      case 'female':
        return 'أنثى';
      default:
        return gender;
    }
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    if (diff.inDays < 30) return 'منذ ${diff.inDays ~/ 7} أسبوع';
    return 'منذ ${diff.inDays ~/ 30} شهر';
  }

  String _resolvePhotoUrl(String url) {
    return ApiConstants.resolveUploadUrl(url) ?? url;
  }

  // ── Photos gallery section ───────────────────────────────────
  Widget _buildPhotosGallery(MissingPersonReport report, bool isDark) {
    if (report.photos.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      isDark: isDark,
      icon: PhosphorIcons.images(),
      title: 'الصور (${report.photos.length})',
      children: [
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: report.photos.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (context, index) {
              final photo = report.photos[index];
              final photoUrl = photo.displayUrl;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: AppColors.surfaceSunken,
      child: Icon(PhosphorIcons.images(), color: AppColors.textLight, size: 32),
    );
  }
}
