import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/incident_reporting_controller.dart';
import '../widgets/severity_selector_widget.dart';
import '../widgets/media_picker_widget.dart';
import '../../../core/constants/incident_constants.dart';

/// Page for reporting new incidents
class IncidentReportingPage extends GetView<IncidentReportingController> {
  const IncidentReportingPage({super.key});

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
            const Text(
              'نوع الحادثة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: IncidentType.values.map((type) {
                    final isSelected = controller.selectedType.value == type;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 18,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(type.displayNameAr),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          controller.changeType(type);
                        }
                      },
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                )),

            const SizedBox(height: 24),

            // Title field
            TextField(
              controller: controller.titleController,
              decoration: InputDecoration(
                labelText: 'عنوان الحادثة *',
                hintText: 'مثال: شخص مفقود في المنطقة الشرقية',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: controller.descriptionController,
              decoration: InputDecoration(
                labelText: 'وصف الحادثة *',
                hintText: 'أدخل تفاصيل الحادثة بشكل دقيق',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 4,
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 16),

            // Location field
            TextField(
              controller: controller.locationController,
              decoration: InputDecoration(
                labelText: 'الموقع *',
                hintText: 'مثال: بوابة رقم 3',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
            Obx(() {
              final severity = controller.selectedSeverity.value;
              return SeveritySelectorWidget(
                selectedSeverity: severity,
                onChanged: controller.changeSeverity,
              );
            }),

            const SizedBox(height: 24),

            // Media picker
            Obx(() {
              final files = controller.selectedMediaFiles.toList();
              return MediaPickerWidget(
                mediaFiles: files,
                onPickImage: controller.pickImage,
                onTakePhoto: controller.takePhoto,
                onPickVideo: controller.pickVideo,
                onRemoveFile: controller.removeMediaFile,
              );
            }),

            const SizedBox(height: 24),

            // Submit button
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.submitIncident,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send),
                              SizedBox(width: 8),
                              Text(
                                'إرسال البلاغ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
