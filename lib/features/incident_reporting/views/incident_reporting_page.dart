import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/incident_reporting_controller.dart';
import '../widgets/severity_selector_widget.dart';
import '../widgets/media_picker_widget.dart';
import '../../../core/constants/incident_constants.dart';

/// Page for reporting new incidents
class IncidentReportingPage extends GetView<IncidentReportingController> {
  const IncidentReportingPage({super.key});

  // ── helpers ────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إبلاغ عن حادثة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident type selector
            _buildSectionHeader(Icons.category_outlined, 'نوع الحادثة'),
            const SizedBox(height: 12),
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
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type.icon,
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                type.displayNameAr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )),

            const SizedBox(height: 24),

            // Title field
            _buildSectionHeader(Icons.title, 'تفاصيل الحادثة'),
            const SizedBox(height: 12),
            TextField(
              controller: controller.titleController,
              decoration: InputDecoration(
                labelText: 'عنوان الحادثة *',
                hintText: 'مثال: شخص مفقود في المنطقة الشرقية',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 14),

            // Description field
            TextField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                labelText: 'وصف الحادثة *',
                hintText: 'أدخل تفاصيل الحادثة بشكل دقيق',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 4,
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 24),

            // Location field
            _buildSectionHeader(Icons.location_on_outlined, 'الموقع'),
            const SizedBox(height: 12),
            TextField(
              controller: controller.locationController,
              decoration: InputDecoration(
                labelText: 'الموقع *',
                hintText: 'مثال: بوابة رقم 3',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: Obx(() => controller.isLoadingLocation.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: controller.getCurrentLocation,
                        tooltip: 'تحديد الموقع الحالي',
                      )),
              ),
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 24),

            // Severity selector
            _buildSectionHeader(
                Icons.warning_amber_outlined, 'مستوى الخطورة'),
            const SizedBox(height: 12),
            Obx(() {
              final severity = controller.selectedSeverity.value;
              return SeveritySelectorWidget(
                selectedSeverity: severity,
                onChanged: controller.changeSeverity,
              );
            }),

            const SizedBox(height: 24),

            // Media picker
            _buildSectionHeader(Icons.photo_camera_outlined, 'الصور والفيديو'),
            const SizedBox(height: 12),
            Obx(() {
              final files = controller.selectedMediaFiles.toList();
              return MediaPickerWidget(
                mediaFiles: files,
                onPickImage: controller.pickImage,
                onTakePhoto: controller.takePhoto,
                onRemoveFile: controller.removeMediaFile,
              );
            }),

            const SizedBox(height: 28),

            // Submit button — gradient
            Obx(() => GestureDetector(
                  onTap: controller.isSubmitting.value
                      ? null
                      : controller.submitReport,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: controller.isSubmitting.value
                          ? null
                          : const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFFD946EF),
                              ],
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                            ),
                      color: controller.isSubmitting.value
                          ? Colors.grey
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: controller.isSubmitting.value
                          ? null
                          : [
                              BoxShadow(
                                color:
                                    const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isSubmitting.value)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          )
                        else ...[  
                          const Icon(Icons.send, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            'إرسال البلاغ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 16),

            // Required fields note
            Text(
              '* حقول إلزامية',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
