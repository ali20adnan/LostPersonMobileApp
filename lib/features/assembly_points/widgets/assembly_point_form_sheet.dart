import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/services/api_service.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/assembly_point_model.dart';
import '../assembly_point_visuals.dart';
import '../controllers/assembly_points_controller.dart';

/// Non-modal bottom panel to create or edit an assembly point — mirrors the
/// web's create/edit sheet. It stays open ABOVE an interactive map, so the
/// draggable draft pin can be moved while the form is visible (this unifies
/// "create", "edit" and "relocate" into a single flow exactly like the web).
///
/// [latitude]/[longitude] are the LIVE draft coordinates (from the page's
/// draggable pin); they update as the pin is dragged. [onClose] dismisses the
/// panel. For **edit**, pass [existing].
class AssemblyPointFormSheet extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final AssemblyPoint? existing;
  final VoidCallback onClose;

  const AssemblyPointFormSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onClose,
    this.existing,
  });

  bool get isEdit => existing != null;

  @override
  State<AssemblyPointFormSheet> createState() => _AssemblyPointFormSheetState();
}

class _AssemblyPointFormSheetState extends State<AssemblyPointFormSheet> {
  final _controller = Get.find<AssemblyPointsController>();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _placeCtrl;
  late final TextEditingController _descCtrl;
  late String _color;
  bool _submitting = false;

  // ── Volunteer picker state ──
  List<VolunteerOption> _volunteers = [];
  final Set<int> _selected = {};
  final Set<int> _initial = {};
  bool _loadingVols = true;
  String _volSearch = '';

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _placeCtrl = TextEditingController(text: p?.nearestPlaceName ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _color = (p?.color != null && p!.color!.isNotEmpty)
        ? p.color!
        : kAssemblyPointPalette.first;

    // Pre-select volunteers already linked to this point (edit mode).
    final existingIds = (p?.volunteers ?? const []).map((v) => v.id);
    _initial.addAll(existingIds);
    _selected.addAll(existingIds);
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    final list = await _controller.getVolunteers();
    if (!mounted) return;
    setState(() {
      _volunteers = list;
      _loadingVols = false;
    });
  }

  List<VolunteerOption> get _filteredVolunteers {
    final q = _volSearch.trim();
    if (q.isEmpty) return _volunteers;
    return _volunteers
        .where((v) => v.fullName.contains(q) || v.userName.contains(q))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Location is required (mirrors the web validation).
    if (widget.latitude == null || widget.longitude == null) {
      AppSnackbar.glass('تنبيه', 'يجب تحديد موقع النقطة على الخريطة');
      return;
    }
    setState(() => _submitting = true);

    final name = _nameCtrl.text.trim();
    final place = _placeCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    final ApiResponse res;
    if (widget.isEdit) {
      // Pass the (possibly relocated) coordinates so dragging the pin during
      // edit moves the point — exactly like the web edit flow.
      res = await _controller.updatePoint(
        widget.existing!.id,
        name: name,
        latitude: widget.latitude,
        longitude: widget.longitude,
        nearestPlaceName: place,
        color: _color,
        description: desc,
      );
      // Apply volunteer membership changes after the metadata update.
      if (res.isSuccess) {
        final toAdd = _selected.difference(_initial).toList();
        final toRemove = _initial.difference(_selected).toList();
        await _controller.syncVolunteers(
          widget.existing!.id,
          toAdd: toAdd,
          toRemove: toRemove,
        );
      }
    } else {
      // Volunteers are linked at creation via volunteerIds.
      res = await _controller.createPoint(
        name: name,
        latitude: widget.latitude!,
        longitude: widget.longitude!,
        nearestPlaceName: place,
        color: _color,
        description: desc,
        volunteerIds: _selected.toList(),
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.isSuccess) {
      AppSnackbar.glass(
        'تم',
        widget.isEdit ? 'تم تحديث النقطة بنجاح' : 'تم إنشاء النقطة بنجاح',
      );
      widget.onClose();
    } else {
      AppSnackbar.glass(
        'خطأ',
        res.errorMessage ??
            (widget.isEdit ? 'فشل تحديث النقطة' : 'فشل إنشاء النقطة'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final muted = textColor.withValues(alpha: 0.6);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.6;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH + 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grab handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header: title + live coordinates + close
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEdit
                                ? 'تعديل نقطة التجمّع'
                                : 'إضافة نقطة تجمّع جديدة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Gap(2),
                          _coordsLabel(muted),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Icon(Icons.close, size: 22, color: muted),
                    ),
                  ],
                ),
                const Gap(16),
                _field(
                  controller: _nameCtrl,
                  label: 'اسم النقطة',
                  hint: 'مثال: نقطة تجمّع الكرادة',
                  icon: PhosphorIcons.mapPin(),
                  isDark: isDark,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'يجب إدخال اسم النقطة'
                      : null,
                ),
                const Gap(12),
                _field(
                  controller: _placeCtrl,
                  label: 'اسم أقرب مكان (يدوي)',
                  hint: 'مثال: قرب جامع الإمام علي',
                  icon: PhosphorIcons.navigationArrow(),
                  isDark: isDark,
                ),
                const Gap(12),
                _field(
                  controller: _descCtrl,
                  label: 'وصف (اختياري)',
                  hint: 'ملاحظات إضافية عن النقطة',
                  icon: PhosphorIcons.note(),
                  isDark: isDark,
                  maxLines: 2,
                ),
                const Gap(16),
                Text('لون النقطة',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.8))),
                const Gap(8),
                _colorPicker(),
                const Gap(12),
                _volunteersSection(isDark, textColor),
                const Gap(14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : widget.onClose,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(PhosphorIcons.check()),
                          label: Text(
                              widget.isEdit ? 'حفظ التعديلات' : 'إنشاء النقطة',
                              style: const TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coordsLabel(Color muted) {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) {
      return Text('انقر على الخريطة بالأعلى لتحديد الموقع',
          style: TextStyle(fontSize: 12, color: muted));
    }
    return Text(
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
      textDirection: TextDirection.ltr,
      style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: muted),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      validator: validator,
      style: TextStyle(
          color: isDark ? AppColors.textOnDark : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }

  // ── Volunteer picker ───────────────────────────────────────────
  Widget _volunteersSection(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.userPlus(), size: 18, color: AppColors.accent),
            const Gap(6),
            Text('المتطوعون',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.8))),
            const Spacer(),
            Text('${_selected.length} محدّد',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const Gap(8),
        TextField(
          textDirection: TextDirection.rtl,
          onChanged: (v) => setState(() => _volSearch = v),
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'ابحث عن متطوع...',
            hintTextDirection: TextDirection.rtl,
            isDense: true,
            prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 18),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                      isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
            ),
          ),
        ),
        const Gap(8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(
                color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _loadingVols
              ? const Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : (_filteredVolunteers.isEmpty
                  ? Center(
                      child: Text('لا يوجد متطوعون متاحون',
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.6))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _filteredVolunteers.length,
                      itemBuilder: (_, i) =>
                          _volunteerRow(_filteredVolunteers[i], isDark, textColor),
                    )),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'المتطوع ينتمي لنقطة واحدة فقط — اختياره هنا ينقله من نقطته السابقة. تُطبَّق التغييرات عند الحفظ.',
            style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.6)),
          ),
        ),
      ],
    );
  }

  Widget _volunteerRow(VolunteerOption v, bool isDark, Color textColor) {
    final checked = _selected.contains(v.id);
    // Show "linked elsewhere" only when the volunteer is on a DIFFERENT point
    // and isn't being selected here (selecting moves them).
    final elsewhere = v.assemblyPointId != null &&
        v.assemblyPointId != widget.existing?.id &&
        !checked;

    void toggle() => setState(() {
          if (checked) {
            _selected.remove(v.id);
          } else {
            _selected.add(v.id);
          }
        });

    return InkWell(
      onTap: toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              activeColor: AppColors.accent,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) => toggle(),
            ),
            const Gap(2),
            _volAvatar(v),
            const Gap(8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: textColor)),
                  Text('@${v.userName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.55))),
                ],
              ),
            ),
            if (elsewhere)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'مرتبط بـ: ${v.assemblyPointName ?? "نقطة أخرى"}',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _volAvatar(VolunteerOption v) {
    final resolved = ApiConstants.resolveAvatarUrl(v.avatarUrl);
    if (resolved != null) {
      return CircleAvatar(
        radius: 15,
        backgroundImage: CachedNetworkImageProvider(resolved),
      );
    }
    final initial = v.fullName.isNotEmpty ? v.fullName.characters.first : '؟';
    return CircleAvatar(
      radius: 15,
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      child: Text(initial,
          style: const TextStyle(
              color: AppColors.accent, fontWeight: FontWeight.bold)),
    );
  }

  // ── Color picker: web palette + free custom color ──────────────
  Widget _colorPicker() {
    final inPalette = kAssemblyPointPalette
        .any((h) => h.toUpperCase() == _color.toUpperCase());
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...kAssemblyPointPalette.map((hex) {
          final selected = hex.toUpperCase() == _color.toUpperCase();
          return GestureDetector(
            onTap: () => setState(() => _color = hex),
            child: _swatch(assemblyPointColor(hex), selected),
          );
        }),
        // Free custom color (mirrors the web's <input type="color">).
        GestureDetector(
          onTap: _pickCustomColor,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: inPalette ? Colors.transparent : assemblyPointColor(_color),
              shape: BoxShape.circle,
              border: Border.all(
                color: inPalette
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : Colors.white,
                width: inPalette ? 1.5 : 3,
              ),
              boxShadow: inPalette
                  ? null
                  : [
                      BoxShadow(
                        color: assemblyPointColor(_color).withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
            ),
            child: Icon(Icons.add,
                size: 18,
                color: inPalette
                    ? AppColors.textSecondary
                    : Colors.white.withValues(alpha: 0.9)),
          ),
        ),
      ],
    );
  }

  Widget _swatch(Color color, bool selected) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : Colors.transparent,
          width: 3,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }

  Future<void> _pickCustomColor() async {
    Color temp = assemblyPointColor(_color);
    final picked = await Get.dialog<Color>(
      AlertDialog(
        title: const Text('لون مخصّص'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Get.back(result: temp),
            child: const Text('اختيار'),
          ),
        ],
      ),
    );
    if (picked != null) setState(() => _color = _hexOf(picked));
  }

  String _hexOf(Color c) {
    final rgb = c.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
