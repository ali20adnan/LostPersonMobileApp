import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/services/storage_service.dart';
import '../../../app/themes/app_colors.dart';
import '../../../core/constants/language_constants.dart';
import '../../../data/models/language_model.dart';

/// Google-Translate-style language picker.
/// - Tapping a language saves it as source/target (per [isSource]),
///   adds it to recents, and pops back to the caller.
/// - No auto-detect (the app supports only 5 languages).
class LanguagesPage extends StatefulWidget {
  final bool isSource;

  const LanguagesPage({super.key, required this.isSource});

  @override
  State<LanguagesPage> createState() => _LanguagesPageState();
}

class _LanguagesPageState extends State<LanguagesPage> {
  final StorageService _storage = Get.find<StorageService>();

  List<Language> _recent = [];
  String _currentSourceCode = 'ar';
  String _currentTargetCode = 'en';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recentCodes = await _storage.getRecentLanguages();
    final source = await _storage.getSourceLanguage();
    final target = await _storage.getTargetLanguage();

    final recentLanguages = recentCodes
        .map(LanguageConstants.getLanguageByCode)
        .whereType<Language>()
        .toList();

    setState(() {
      _recent = recentLanguages;
      _currentSourceCode = source;
      _currentTargetCode = target;
      _ready = true;
    });
  }

  Future<void> _select(Language language) async {
    if (widget.isSource) {
      await _storage.saveSourceLanguage(language.code);
    } else {
      await _storage.saveTargetLanguage(language.code);
    }
    await _storage.addRecentLanguage(language.code);
    if (mounted) Get.back();
  }

  String get _currentSelectedCode =>
      widget.isSource ? _currentSourceCode : _currentTargetCode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.isSource ? 'ترجمة من' : 'ترجمة إلى';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowRight()),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: !_ready
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Gap(28),
                    if (_recent.isNotEmpty) ...[
                      _buildSectionHeader('اللغات المستخدمة مؤخرًا', isDark),
                      const Gap(8),
                      ..._recent.map(
                        (lang) => _buildLanguageTile(
                          lang,
                          isDark: isDark,
                          isSelected: lang.code == _currentSelectedCode,
                        ),
                      ),
                      const Gap(24),
                    ],
                    _buildSectionHeader('جميع اللغات', isDark),
                    const Gap(8),
                    ...LanguageConstants.supportedLanguages.map(
                      (lang) => _buildLanguageTile(
                        lang,
                        isDark: isDark,
                        isSelected: lang.code == _currentSelectedCode,
                      ),
                    ),
                    const Gap(24),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    Language language, {
    required bool isDark,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _select(language),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: isSelected
                  ? Icon(
                      PhosphorIcons.check(PhosphorIconsStyle.bold),
                      size: 20,
                      color: AppColors.accent,
                    )
                  : const SizedBox.shrink(),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                language.nameAr,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.accent
                      : (isDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
