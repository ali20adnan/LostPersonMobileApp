import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/shared/morph_submit_button.dart';
import '../controllers/incident_reporting_controller.dart';
import '../widgets/severity_selector_widget.dart';
import '../widgets/media_picker_widget.dart';
import '../../../core/constants/incident_constants.dart';

/// Page for reporting new incidents
class IncidentReportingPage extends GetView<IncidentReportingController> {
  const IncidentReportingPage({super.key});

  // ── helpers ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const Gap(10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.6)
          : AppColors.surfaceSunken.withValues(alpha: 0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(
        color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
      ),
      hintStyle: TextStyle(
        color: isDark
            ? AppColors.textOnDarkSecondary.withValues(alpha: 0.6)
            : AppColors.textLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('إبلاغ عن حادثة'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident type selector
            _buildSectionHeader(PhosphorIcons.squaresFour(), 'نوع الحادثة', isDark)
                .animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
            const Gap(12),
            Obx(() => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: ReportType.values.map((type) {
                    final isSelected = controller.selectedType.value == type;
                    return GestureDetector(
                      onTap: () => controller.changeType(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.heroGradient : null,
                          color: isSelected
                              ? null
                              : isDark
                                  ? AppColors.cardDark
                                  : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : isDark
                                    ? AppColors.cardBorderDark
                                    : AppColors.cardBorder,
                            width: isSelected ? 0 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : AppColors.softShadow,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type.icon,
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                type.displayNameAr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isDark
                                          ? AppColors.textOnDark
                                          : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                PhosphorIcons.checkCircle(),
                                color: Colors.white,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            // Title + Description: hidden for emergency
            Obx(() {
              if (controller.selectedType.value == ReportType.emergency) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(24),
                  _buildSectionHeader(PhosphorIcons.fileText(), 'تفاصيل الحادثة', isDark)
                      .animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.1),
                  const Gap(12),
                  TextField(
                    controller: controller.titleController,
                    decoration: _inputDecoration(
                      label: 'عنوان الحادثة *',
                      hint: 'مثال: شخص مفقود في المنطقة الشرقية',
                      icon: PhosphorIcons.textT(),
                      isDark: isDark,
                    ),
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
                  const Gap(14),
                  TextField(
                    controller: controller.descriptionController,
                    decoration: _inputDecoration(
                      label: 'وصف الحادثة *',
                      hint: 'أدخل تفاصيل الحادثة بشكل دقيق',
                      icon: PhosphorIcons.notepad(),
                      isDark: isDark,
                    ),
                    maxLines: 4,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                ],
              );
            }),

            const Gap(24),

            // Auto-location status indicator
            Obx(() {
              final isLoading = controller.isLoadingLocation.value;
              final hasLocation = controller.currentLocation.value != null;
              return Row(
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'جاري تحديد الموقع...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ] else if (hasLocation) ...[
                    Icon(PhosphorIcons.checkCircle(),
                        color: Colors.green, size: 16),
                    const Gap(8),
                    const Text(
                      'تم تحديد الموقع',
                      style: TextStyle(fontSize: 13, color: Colors.green),
                    ),
                  ] else ...[
                    Icon(PhosphorIcons.warningCircle(),
                        color: Colors.orange, size: 16),
                    const Gap(8),
                    const Text(
                      'تعذّر تحديد الموقع',
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ],
                ],
              );
            }).animate().fadeIn(duration: 400.ms, delay: 350.ms),

            const Gap(24),

            // Severity selector
            _buildSectionHeader(PhosphorIcons.warningCircle(), 'مستوى الخطورة', isDark)
                .animate().fadeIn(duration: 400.ms, delay: 450.ms).slideX(begin: -0.1),
            const Gap(12),
            Obx(() {
              final severity = controller.selectedSeverity.value;
              return SeveritySelectorWidget(
                selectedSeverity: severity,
                onChanged: controller.changeSeverity,
              );
            }).animate().fadeIn(duration: 400.ms, delay: 500.ms),

            // Media picker: hidden for emergency
            Obx(() {
              if (controller.selectedType.value == ReportType.emergency) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(24),
                  _buildSectionHeader(PhosphorIcons.camera(), 'الصور والفيديو', isDark)
                      .animate().fadeIn(duration: 400.ms, delay: 550.ms).slideX(begin: -0.1),
                  const Gap(12),
                  Obx(() {
                    final files = controller.selectedMediaFiles.toList();
                    return MediaPickerWidget(
                      mediaFiles: files,
                      onPickImage: controller.pickImage,
                      onTakePhoto: controller.takePhoto,
                      onPickVideo: controller.pickVideo,
                      onRemoveFile: controller.removeMediaFile,
                    );
                  }).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                ],
              );
            }),

            const Gap(28),

            // Submit button — morphs to spinner during submit
            Obx(() => MorphSubmitButton(
                  label: 'إرسال البلاغ',
                  icon: PhosphorIcons.paperPlaneTilt(),
                  isSubmitting: controller.isSubmitting.value,
                  onPressed: controller.submitReport,
                ))
                .animate()
                .fadeIn(duration: 500.ms, delay: 650.ms)
                .slideY(begin: 0.1),

            const Gap(16),

            // Required fields note: hidden for emergency
            Obx(() {
              if (controller.selectedType.value == ReportType.emergency) {
                return const SizedBox.shrink();
              }
              return Text(
                '* حقول إلزامية',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textOnDarkSecondary : AppColors.textLight,
                ),
              );
            }),

            const Gap(32),
          ],
        ),
      ),
    );
  }
}
