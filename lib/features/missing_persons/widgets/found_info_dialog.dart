import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_translator_app/core/utils/icon_direction.dart';

import '../../../app/themes/app_colors.dart';

/// Dialog to collect found person information before sending the request.
class FoundInfoDialog extends StatefulWidget {
  const FoundInfoDialog({super.key});

  /// Shows the dialog and returns the collected data, or null if cancelled.
  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FoundInfoDialog(),
    );
  }

  @override
  State<FoundInfoDialog> createState() => _FoundInfoDialogState();
}

class _FoundInfoDialogState extends State<FoundInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _foundDate = DateTime.now();
  final _locationController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _foundDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'foundDate': _foundDate.toIso8601String().split('T')[0],
    };

    final location = _locationController.text.trim();
    if (location.isNotEmpty) data['foundLocation'] = location;

    final reason = _reasonController.text.trim();
    if (reason.isNotEmpty) data['foundReason'] = reason;

    final notes = _notesController.text.trim();
    if (notes.isNotEmpty) data['notes'] = notes;

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(PhosphorIcons.checkCircle().ltr,
                      color: AppColors.teal, size: 32),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تأكيد العثور على الشخص',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'أدخل معلومات العثور',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Found Date
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'تاريخ العثور *',
                      prefixIcon: Icon(PhosphorIcons.calendar(),
                          color: AppColors.teal, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.teal.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: Text(
                      '${_foundDate.year}/${_foundDate.month.toString().padLeft(2, '0')}/${_foundDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Found Location
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'مكان العثور',
                    hintText: 'مثال: بغداد، الكرادة...',
                    prefixIcon: Icon(PhosphorIcons.mapPin(),
                        color: AppColors.teal, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Found Reason
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'سبب العثور',
                    hintText: 'مثال: تم العثور عليه من قبل فريق البحث...',
                    prefixIcon: Icon(PhosphorIcons.fileText(),
                        color: AppColors.teal, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات',
                    hintText: 'تفاصيل إضافية حول العثور...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(PhosphorIcons.notepad(),
                          color: AppColors.teal, size: 20),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.successGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _submit,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIcons.checkCircle().ltr,
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'تأكيد',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
