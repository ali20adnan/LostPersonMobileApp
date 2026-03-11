import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/missing_person_form_controller.dart';

class MissingPersonFormPage extends GetView<MissingPersonFormController> {
  const MissingPersonFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إبلاغ عن مفقود'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCollapsibleSection(
              theme: theme,
              index: 0,
              icon: Icons.person_outline,
              title: 'معلومات الشخص',
              children: [
                _buildTextField(
                  controller: controller.fullNameController,
                  label: 'الاسم الكامل *',
                  icon: Icons.person,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildGenderSelector(theme),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.dateOfBirthController,
                  label: 'تاريخ الميلاد',
                  icon: Icons.cake,
                  hint: 'YYYY-MM-DD',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.heightController,
                        label: 'الطول (سم)',
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.weightController,
                        label: 'الوزن (كغ)',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: TextInputType.number,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.hairColorController,
                        label: 'لون الشعر',
                        icon: Icons.face,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.eyeColorController,
                        label: 'لون العين',
                        icon: Icons.remove_red_eye_outlined,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.distinguishingFeaturesController,
                  label: 'علامات مميزة',
                  icon: Icons.star_outline,
                  maxLines: 2,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.medicalConditionsController,
                  label: 'حالات طبية',
                  icon: Icons.medical_services_outlined,
                  maxLines: 2,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.clothingDescriptionController,
                  label: 'وصف الملابس',
                  icon: Icons.checkroom,
                  maxLines: 2,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              theme: theme,
              index: 1,
              icon: Icons.location_on_outlined,
              title: 'آخر موقع شوهد فيه',
              children: [
                _buildTextField(
                  controller: controller.addressLineController,
                  label: 'العنوان',
                  icon: Icons.location_on,
                  theme: theme,
                  suffixWidget: Obx(() => controller.isLoadingLocation.value
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
              ],
            ),
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              theme: theme,
              index: 3,
              icon: Icons.contact_phone_outlined,
              title: 'معلومات المُبلّغ',
              children: [
                _buildTextField(
                  controller: controller.reporterNameController,
                  label: 'اسم المُبلّغ *',
                  icon: Icons.person,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.reporterPhoneController,
                  label: 'رقم الهاتف *',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.reporterRelationshipController,
                  label: 'صلة القرابة',
                  icon: Icons.group,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              theme: theme,
              index: 4,
              icon: Icons.article_outlined,
              title: 'تفاصيل البلاغ',
              children: [
                GestureDetector(
                  onTap: () => controller.pickDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: controller.missingDateController,
                      label: 'تاريخ الفقدان *',
                      icon: Icons.calendar_today,
                      theme: theme,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.descriptionController,
                  label: 'وصف إضافي',
                  icon: Icons.description,
                  maxLines: 3,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildPhotoPicker(theme),
              ],
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required ThemeData theme,
    required int index,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Obx(() {
      final isExpanded = controller.expandedSections.contains(index);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => controller.toggleSection(index),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(children: children),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffixWidget,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
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
        prefixIcon: Icon(icon),
        suffixIcon: suffixWidget,
      ),
    );
  }

  Widget _buildGenderSelector(ThemeData theme) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: _genderChip(theme, 'male', 'ذكر', Icons.male),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _genderChip(theme, 'female', 'أنثى', Icons.female),
            ),
          ],
        ));
  }

  Widget _genderChip(
      ThemeData theme, String value, String label, IconData icon) {
    final isSelected = controller.selectedGender.value == value;
    return GestureDetector(
      onTap: () => controller.selectedGender.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? Colors.white : theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_camera_outlined,
                size: 20, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            const Text('الصور',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.pickImage,
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('المعرض'),
            ),
            TextButton.icon(
              onPressed: controller.takePhoto,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('الكاميرا'),
            ),
          ],
        ),
        Obx(() {
          if (controller.selectedPhotos.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text('لم يتم اختيار صور',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.selectedPhotos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(controller.selectedPhotos[index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => controller.removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Obx(() => GestureDetector(
          onTap: controller.isSubmitting.value
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  controller.submitReport();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: controller.isSubmitting.value
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
              color: controller.isSubmitting.value ? Colors.grey : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: controller.isSubmitting.value
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'إرسال البلاغ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ));
  }
}
