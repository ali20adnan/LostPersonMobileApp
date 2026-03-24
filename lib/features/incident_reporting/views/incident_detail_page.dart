import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/constants/incident_constants.dart';
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
        if (report.latitude != null && report.longitude != null)
          _buildInfoRow(
            isDark,
            'الإحداثيات',
            '${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
          ),
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
}
