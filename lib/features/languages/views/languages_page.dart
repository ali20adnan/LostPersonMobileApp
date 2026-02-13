import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/languages_controller.dart';
import '../widgets/language_card.dart';

class LanguagesPage extends GetView<LanguagesController> {
  const LanguagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'اختيار اللغة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          // Top decoration
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Source Language Section
                _buildSectionHeader(
                  context,
                  'اللغة المصدر',
                  'Source Language',
                  Icons.mic_rounded,
                ),
                const SizedBox(height: 8),
                Obx(() => _buildLanguageList(
                      context,
                      isSource: true,
                    )),

                const SizedBox(height: 24),

                // Swap Button
                _buildSwapButton(context),

                const SizedBox(height: 24),

                // Target Language Section
                _buildSectionHeader(
                  context,
                  'اللغة الهدف',
                  'Target Language',
                  Icons.translate_rounded,
                ),
                const SizedBox(height: 8),
                Obx(() => _buildLanguageList(
                      context,
                      isSource: false,
                    )),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // Floating Save Button
      floatingActionButton: _buildSaveButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String titleAr,
    String titleEn,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleAr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              Text(
                titleEn,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList(BuildContext context, {required bool isSource}) {
    final selectedLanguage = isSource
        ? controller.selectedSourceLanguage.value
        : controller.selectedTargetLanguage.value;

    return Column(
      children: controller.availableLanguages.map((language) {
        final isSelected = language.code == selectedLanguage.code;

        return LanguageCard(
          language: language,
          isSelected: isSelected,
          onTap: () {
            if (isSource) {
              controller.selectSourceLanguage(language);
            } else {
              controller.selectTargetLanguage(language);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSwapButton(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.swapLanguages,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'تبديل اللغات',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      child: ElevatedButton(
        onPressed: controller.saveAndGoBack,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 4,
          shadowColor: theme.colorScheme.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 20),
            const SizedBox(width: 10),
            Text(
              'حفظ التغييرات',
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 15,
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
