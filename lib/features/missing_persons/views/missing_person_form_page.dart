import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/missing_person_form_controller.dart';

class MissingPersonFormPage extends GetView<MissingPersonFormController> {
  const MissingPersonFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('إبلاغ عن مفقود'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCollapsibleSection(
              isDark: isDark,
              index: 0,
              icon: Iconsax.user,
              title: 'معلومات الشخص',
              children: [
                _buildTextField(
                  controller: controller.fullNameController,
                  label: 'الاسم الكامل *',
                  icon: Iconsax.user,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildGenderSelector(isDark),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.dateOfBirthController,
                  label: 'تاريخ الميلاد',
                  icon: Iconsax.cake,
                  hint: 'YYYY-MM-DD',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.heightController,
                        label: 'الطول (سم)',
                        icon: Iconsax.ruler,
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.weightController,
                        label: 'الوزن (كغ)',
                        icon: Iconsax.weight,
                        keyboardType: TextInputType.number,
                        isDark: isDark,
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
                        icon: Iconsax.activity,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.eyeColorController,
                        label: 'لون العين',
                        icon: Iconsax.eye,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.distinguishingFeaturesController,
                  label: 'علامات مميزة',
                  icon: Iconsax.star,
                  maxLines: 2,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.medicalConditionsController,
                  label: 'حالات طبية',
                  icon: Iconsax.health,
                  maxLines: 2,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.clothingDescriptionController,
                  label: 'وصف الملابس',
                  icon: Iconsax.bag_2,
                  maxLines: 2,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              isDark: isDark,
              index: 1,
              icon: Iconsax.location,
              title: 'آخر موقع شوهد فيه',
              children: [
                _buildTextField(
                  controller: controller.addressLineController,
                  label: 'العنوان',
                  icon: Iconsax.location,
                  isDark: isDark,
                  suffixWidget: Obx(() => controller.isLoadingLocation.value
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Iconsax.gps, color: AppColors.primary),
                          onPressed: controller.getCurrentLocation,
                          tooltip: 'تحديد الموقع الحالي',
                        )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              isDark: isDark,
              index: 3,
              icon: Iconsax.call,
              title: 'معلومات المُبلّغ',
              children: [
                _buildTextField(
                  controller: controller.reporterNameController,
                  label: 'اسم المُبلّغ *',
                  icon: Iconsax.user,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.reporterPhoneController,
                  label: 'رقم الهاتف *',
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.reporterRelationshipController,
                  label: 'صلة القرابة',
                  icon: Iconsax.people,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              isDark: isDark,
              index: 4,
              icon: Iconsax.document_text,
              title: 'تفاصيل البلاغ',
              children: [
                GestureDetector(
                  onTap: () => controller.pickDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: controller.missingDateController,
                      label: 'تاريخ الفقدان *',
                      icon: Iconsax.calendar,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.descriptionController,
                  label: 'وصف إضافي',
                  icon: Iconsax.document,
                  maxLines: 3,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildPhotoPicker(isDark),
              ],
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required bool isDark,
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
          color: isDark ? AppColors.cardDark : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: isDark ? null : AppColors.cardShadow,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => controller.toggleSection(index),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(children: children),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
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
    required bool isDark,
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
        fillColor: isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        suffixIcon: suffixWidget,
      ),
    );
  }

  Widget _buildGenderSelector(bool isDark) {
    return Obx(() => Row(
          children: [
            Expanded(child: _genderChip(isDark, 'male', 'ذكر', Iconsax.man)),
            const SizedBox(width: 10),
            Expanded(child: _genderChip(isDark, 'female', 'أنثى', Iconsax.woman)),
          ],
        ));
  }

  Widget _genderChip(bool isDark, String value, String label, IconData icon) {
    final isSelected = controller.selectedGender.value == value;
    return GestureDetector(
      onTap: () => controller.selectedGender.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.heroGradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.border),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Iconsax.camera, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'الصور',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.pickImage,
              icon: const Icon(Iconsax.gallery, size: 18),
              label: const Text('المعرض'),
            ),
            TextButton.icon(
              onPressed: controller.takePhoto,
              icon: const Icon(Iconsax.camera, size: 18),
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
                color: isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(Iconsax.gallery_add, size: 40, color: AppColors.textLight),
                  const SizedBox(height: 8),
                  Text('لم يتم اختيار صور',
                      style: TextStyle(color: AppColors.textSecondary)),
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
                        borderRadius: BorderRadius.circular(12),
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
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
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

  Widget _buildSubmitButton(bool isDark) {
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
              gradient: controller.isSubmitting.value ? null : AppColors.heroGradient,
              color: controller.isSubmitting.value ? AppColors.textLight : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: controller.isSubmitting.value
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: controller.isSubmitting.value
                  ? LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.white,
                      size: 24,
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.send_1, color: Colors.white),
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
          ).animate().fadeIn(delay: 200.ms),
        ));
  }
}
