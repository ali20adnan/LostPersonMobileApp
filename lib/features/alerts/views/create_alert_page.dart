import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/alerts_controller.dart';

/// Page for creating a new alert (sighting report) for a missing person
class CreateAlertPage extends GetView<AlertsController> {
  const CreateAlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get missingPersonReportId and personName from arguments
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final reportId = args['missingPersonReportId'] as int? ?? 0;
    final personName = args['personName'] as String? ?? 'شخص مفقود';

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final descController = TextEditingController();
    final selectedType = 'sighting'.obs;

    final types = [
      {'key': 'sighting', 'label': 'مشاهدة', 'icon': Iconsax.eye, 'color': AppColors.info},
      {'key': 'tip', 'label': 'معلومة', 'icon': Iconsax.lamp_on, 'color': AppColors.warning},
      {'key': 'found', 'label': 'تم العثور', 'icon': Iconsax.tick_circle, 'color': AppColors.success},
      {'key': 'information', 'label': 'معلومات عامة', 'icon': Iconsax.info_circle, 'color': AppColors.primary},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('الإبلاغ عن مشاهدة'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_right_3),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Person info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.search_status, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الإبلاغ عن',
                          style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          personName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

            const SizedBox(height: 20),

            // Type selector
            Text(
              'نوع البلاغ',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types.map((t) {
                    final isSelected = selectedType.value == t['key'];
                    final color = t['color'] as Color;
                    return GestureDetector(
                      onTap: () => selectedType.value = t['key'] as String,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? AppColors.surfaceDark : AppColors.surfaceSunken),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.border),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t['icon'] as IconData, size: 18, color: isSelected ? color : AppColors.textLight),
                            const SizedBox(width: 6),
                            Text(
                              t['label'] as String,
                              style: TextStyle(
                                color: isSelected ? color : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )),

            const SizedBox(height: 20),

            // Reporter name
            _buildField(
              theme: theme,
              isDark: isDark,
              label: 'اسم المُبلِّغ',
              icon: Iconsax.user,
              controller: nameController,
              hint: 'أدخل اسمك الكامل',
            ),

            const SizedBox(height: 14),

            // Reporter phone
            _buildField(
              theme: theme,
              isDark: isDark,
              label: 'رقم الهاتف',
              icon: Iconsax.call,
              controller: phoneController,
              hint: '07XXXXXXXXX',
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 14),

            // Description
            _buildField(
              theme: theme,
              isDark: isDark,
              label: 'الوصف والتفاصيل',
              icon: Iconsax.document_text,
              controller: descController,
              hint: 'صف ما شاهدته أو المعلومات التي لديك...',
              maxLines: 4,
            ),

            const SizedBox(height: 28),

            // Submit button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: controller.isSubmitting.value
                            ? null
                            : () => _submit(
                                  reportId: reportId,
                                  type: selectedType.value,
                                  name: nameController,
                                  phone: phoneController,
                                  desc: descController,
                                ),
                        child: Center(
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.send_1, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'إرسال البلاغ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                )),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: hint,
            hintTextDirection: TextDirection.rtl,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceSunken,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _submit({
    required int reportId,
    required String type,
    required TextEditingController name,
    required TextEditingController phone,
    required TextEditingController desc,
  }) async {
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty || desc.text.trim().isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى ملء جميع الحقول المطلوبة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warningLight,
        colorText: AppColors.warning,
      );
      return;
    }

    final success = await controller.createAlert(
      missingPersonReportId: reportId,
      type: type,
      reporterName: name.text.trim(),
      reporterPhone: phone.text.trim(),
      description: desc.text.trim(),
    );

    if (success) {
      Get.back();
      Get.snackbar(
        'تم بنجاح',
        'تم إرسال البلاغ بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
      );
    } else {
      Get.snackbar(
        'خطأ',
        'فشل في إرسال البلاغ، حاول مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
      );
    }
  }
}
