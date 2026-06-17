import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/shared/morph_submit_button.dart';
import '../../../data/models/governorate_model.dart';
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
            _buildModeToggle(isDark),
            const SizedBox(height: 16),
            Obx(() => controller.isBriefForm.value
                ? _buildBriefForm(context, isDark)
                : _buildFullForm(context, isDark)),
            const SizedBox(height: 24),
            _buildSubmitButton(isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Segmented toggle between the full report and the brief report.
  Widget _buildModeToggle(bool isDark) {
    Widget tab(String label, bool brief) {
      final isSelected = controller.isBriefForm.value == brief;
      return Expanded(
        child: GestureDetector(
          onTap: () => controller.setBriefForm(brief),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.heroGradient : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      );
    }

    return Obx(() => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              tab('بلاغ كامل', false),
              tab('بلاغ مختصر', true),
            ],
          ),
        ));
  }

  /// The full multi-section report (original form).
  Widget _buildFullForm(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Section 0 - Person Info
        _buildCollapsibleSection(
          isDark: isDark,
          index: 0,
          icon: PhosphorIcons.user(),
          title: 'معلومات الشخص',
          children: [
            _buildTextField(
              controller: controller.fullNameController,
              label: 'الاسم الكامل *',
              icon: PhosphorIcons.user(),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildGenderSelector(isDark),
            const SizedBox(height: 12),
            _buildTextField(
              controller: controller.ageController,
              label: 'العمر',
              icon: PhosphorIcons.cake(),
              keyboardType: TextInputType.number,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.heightController,
                        label: 'الطول (سم)',
                        icon: PhosphorIcons.ruler(),
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.weightController,
                        label: 'الوزن (كغ)',
                        icon: PhosphorIcons.scales(),
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildOptionPickerField(
                  label: 'لون الشعر',
                  options: MissingPersonFormController.hairColorOptions,
                  selected: controller.selectedHairColor,
                  icon: PhosphorIcons.palette(),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildOptionPickerField(
                  label: 'لون العين',
                  options: MissingPersonFormController.eyeColorOptions,
                  selected: controller.selectedEyeColor,
                  icon: PhosphorIcons.eye(),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.distinguishingFeaturesController,
                  label: 'علامات مميزة',
                  icon: PhosphorIcons.star(),
                  maxLines: 2,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.medicalConditionsController,
                  label: 'حالات طبية',
                  icon: PhosphorIcons.firstAid(),
                  maxLines: 2,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.clothingDescriptionController,
                  label: 'وصف الملابس',
                  icon: PhosphorIcons.tShirt(),
                  maxLines: 2,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.descriptionController,
                  label: 'وصف إضافي',
                  icon: PhosphorIcons.file(),
                  maxLines: 3,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => controller.pickDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: controller.missingDateController,
                      label: 'تاريخ الفقدان *',
                      icon: PhosphorIcons.calendar(),
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Section 1 - Residence
            _buildCollapsibleSection(
              isDark: isDark,
              index: 1,
              icon: PhosphorIcons.house(),
              title: 'مكان السكن الأصلي',
              children: [
                _buildGovernoratePickerField(isDark),
                const SizedBox(height: 12),
                _buildDistrictPickerField(isDark),
              ],
            ),
            const SizedBox(height: 12),
            // Section 2 - Last seen location
            _buildCollapsibleSection(
              isDark: isDark,
              index: 2,
              icon: PhosphorIcons.mapPin(),
              title: 'آخر موقع شوهد فيه',
              children: [
                _buildTextField(
                  controller: controller.addressLineController,
                  label: 'العنوان',
                  icon: PhosphorIcons.mapPin(),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final loc = controller.selectedMapLocation.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => controller.openMapPicker(context),
                          icon: Icon(PhosphorIcons.mapPin()),
                          label: Text(loc == null
                              ? 'تحديد على الخريطة'
                              : 'تعديل الموقع'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (loc != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.mapPin(),
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            // Section 3 - Reporter Info
            _buildCollapsibleSection(
              isDark: isDark,
              index: 3,
              icon: PhosphorIcons.phone(),
              title: 'معلومات المُبلّغ',
              children: [
                _buildTextField(
                  controller: controller.reporterNameController,
                  label: 'اسم المُبلّغ *',
                  icon: PhosphorIcons.user(),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.reporterPhoneController,
                  label: 'رقم الهاتف *',
                  icon: PhosphorIcons.phone(),
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.reporterRelationshipController,
                  label: 'صلة القرابة',
                  icon: PhosphorIcons.users(),
                  isDark: isDark,
                ),
              ],
            ),
        const SizedBox(height: 12),
        // Section 4 - Photos
        _buildCollapsibleSection(
          isDark: isDark,
          index: 4,
          icon: PhosphorIcons.camera(),
          title: 'الصور *',
          children: [
            _buildPhotoPicker(isDark),
          ],
        ),
      ],
    );
  }

  /// The brief report: only name, age, gender, governorate, photo + reporter.
  Widget _buildBriefForm(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildCollapsibleSection(
          isDark: isDark,
          index: 0,
          icon: PhosphorIcons.user(),
          title: 'معلومات الشخص',
          children: [
            _buildTextField(
              controller: controller.fullNameController,
              label: 'الاسم الكامل *',
              icon: PhosphorIcons.user(),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildGenderSelector(isDark),
            const SizedBox(height: 12),
            _buildTextField(
              controller: controller.ageController,
              label: 'العمر *',
              icon: PhosphorIcons.cake(),
              keyboardType: TextInputType.number,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          isDark: isDark,
          index: 1,
          icon: PhosphorIcons.house(),
          title: 'المحافظة',
          children: [
            _buildGovernoratePickerField(isDark),
          ],
        ),
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          isDark: isDark,
          index: 3,
          icon: PhosphorIcons.phone(),
          title: 'معلومات المُبلّغ',
          children: [
            _buildBriefReporterSection(isDark),
          ],
        ),
        const SizedBox(height: 12),
        _buildCollapsibleSection(
          isDark: isDark,
          index: 4,
          icon: PhosphorIcons.camera(),
          title: 'الصورة',
          children: [
            _buildPhotoPicker(isDark),
          ],
        ),
      ],
    );
  }

  /// Reporter block for the brief form: defaults to the logged-in user (name
  /// only); a toggle reveals name + phone + relationship for another reporter.
  Widget _buildBriefReporterSection(bool isDark) {
    return Obx(() {
      final isOther = controller.reporterIsOther.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: isOther,
            onChanged: (value) => controller.reporterIsOther.value = value,
            title: Text(
              'المُبلّغ شخص آخر',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              isOther
                  ? 'أدخل بيانات المُبلّغ (شخص ليس لديه حساب)'
                  : 'سيُسجَّل البلاغ باسمك: '
                      '${controller.defaultReporterName.isNotEmpty ? controller.defaultReporterName : 'المستخدم الحالي'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          if (isOther) ...[
            const SizedBox(height: 8),
            _buildTextField(
              controller: controller.reporterNameController,
              label: 'اسم المُبلّغ *',
              icon: PhosphorIcons.user(),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: controller.reporterPhoneController,
              label: 'رقم الهاتف *',
              icon: PhosphorIcons.phone(),
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: controller.reporterRelationshipController,
              label: 'صلته بالمفقود',
              icon: PhosphorIcons.users(),
              isDark: isDark,
            ),
          ],
        ],
      );
    });
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
                  isExpanded ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
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
            Expanded(child: _genderChip(isDark, 'male', 'ذكر', PhosphorIcons.genderMale())),
            const SizedBox(width: 10),
            Expanded(child: _genderChip(isDark, 'female', 'أنثى', PhosphorIcons.genderFemale())),
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

  /// Bottom-sheet option picker (hair/eye color etc.)
  Widget _buildOptionPickerField({
    required String label,
    required List<String> options,
    required Rx<String?> selected,
    required IconData icon,
    required bool isDark,
  }) {
    return Obx(() {
      final value = selected.value;
      return GestureDetector(
        onTap: () async {
          final picked = await showModalBottomSheet<String>(
            context: Get.context!,
            backgroundColor:
                isDark ? AppColors.cardDark : AppColors.card,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: options
                        .map((opt) => ListTile(
                              title: Text(opt,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: isDark
                                          ? AppColors.textOnDark
                                          : AppColors.textPrimary)),
                              trailing: selected.value == opt
                                  ? const Icon(Icons.check,
                                      color: AppColors.primary)
                                  : null,
                              onTap: () => Navigator.pop(Get.context!, opt),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
          if (picked != null) selected.value = picked;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceSunkenDark
                : AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? label,
                  style: TextStyle(
                    color: value != null
                        ? (isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary)
                        : AppColors.textLight,
                  ),
                ),
              ),
              Icon(PhosphorIcons.caretDown(), size: 18, color: AppColors.textLight),
            ],
          ),
        ),
      );
    });
  }

  /// Governorate dropdown-style picker
  Widget _buildGovernoratePickerField(bool isDark) {
    return Obx(() {
      final isLoading = controller.isLoadingGovernorates.value;
      final selected = controller.selectedResidenceGovernorate.value;
      return GestureDetector(
        onTap: isLoading
            ? null
            : () async {
                if (controller.governorates.isEmpty) return;
                final picked = await showModalBottomSheet<Governorate>(
                  context: Get.context!,
                  backgroundColor:
                      isDark ? AppColors.cardDark : AppColors.card,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text('اختر المحافظة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textPrimary,
                          )),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: controller.governorates
                              .map((gov) => ListTile(
                                    title: Text(gov.name,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            color: isDark
                                                ? AppColors.textOnDark
                                                : AppColors.textPrimary)),
                                    trailing: selected?.id == gov.id
                                        ? const Icon(Icons.check,
                                            color: AppColors.primary)
                                        : null,
                                    onTap: () =>
                                        Navigator.pop(Get.context!, gov),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
                if (picked != null) {
                  controller.onResidenceGovernorateChanged(picked);
                }
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceSunkenDark
                : AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.house(), size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        selected?.name ?? 'المحافظة',
                        style: TextStyle(
                          color: selected != null
                              ? (isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary)
                              : AppColors.textLight,
                        ),
                      ),
              ),
              Icon(PhosphorIcons.caretDown(),
                  size: 18, color: AppColors.textLight),
            ],
          ),
        ),
      );
    });
  }

  /// District picker (disabled until governorate selected)
  Widget _buildDistrictPickerField(bool isDark) {
    return Obx(() {
      final gov = controller.selectedResidenceGovernorate.value;
      final selected = controller.selectedResidenceDistrict.value;
      final districts = controller.availableResidenceDistricts;
      final enabled = gov != null && districts.isNotEmpty;
      return GestureDetector(
        onTap: enabled
            ? () async {
                final picked = await showModalBottomSheet<District>(
                  context: Get.context!,
                  backgroundColor:
                      isDark ? AppColors.cardDark : AppColors.card,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text('اختر القضاء',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textPrimary,
                          )),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: districts
                              .map((dist) => ListTile(
                                    title: Text(dist.name,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            color: isDark
                                                ? AppColors.textOnDark
                                                : AppColors.textPrimary)),
                                    trailing: selected?.id == dist.id
                                        ? const Icon(Icons.check,
                                            color: AppColors.primary)
                                        : null,
                                    onTap: () =>
                                        Navigator.pop(Get.context!, dist),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
                if (picked != null) {
                  controller.selectedResidenceDistrict.value = picked;
                }
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: enabled
                ? (isDark
                    ? AppColors.surfaceSunkenDark
                    : AppColors.surfaceSunken)
                : (isDark
                    ? AppColors.surfaceSunkenDark.withValues(alpha: 0.5)
                    : AppColors.surfaceSunken.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.mapPin(),
                  size: 20,
                  color: enabled ? AppColors.primary : AppColors.textLight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selected?.name ?? 'القضاء',
                  style: TextStyle(
                    color: selected != null
                        ? (isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary)
                        : AppColors.textLight,
                  ),
                ),
              ),
              Icon(PhosphorIcons.caretDown(),
                  size: 18, color: AppColors.textLight),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPhotoPicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.camera(), size: 20, color: AppColors.primary),
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
              icon: Icon(PhosphorIcons.images(), size: 18),
              label: const Text('المعرض'),
            ),
            TextButton.icon(
              onPressed: controller.takePhoto,
              icon: Icon(PhosphorIcons.camera(), size: 18),
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
                  Icon(PhosphorIcons.cameraPlus(), size: 40, color: AppColors.textLight),
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
                            child: Icon(PhosphorIcons.x(), size: 14, color: Colors.white),
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
    return Obx(() => MorphSubmitButton(
          label: 'إرسال البلاغ',
          icon: PhosphorIcons.paperPlaneTilt(),
          isSubmitting: controller.isSubmitting.value,
          onPressed: () {
            HapticFeedback.mediumImpact();
            controller.submitReport();
          },
        ).animate().fadeIn(delay: 200.ms));
  }
}
