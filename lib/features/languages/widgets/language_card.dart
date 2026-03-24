import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../data/models/language_model.dart';

class LanguageCard extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageCard({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.heroGradient : null,
          color: isSelected ? null : (isDark ? AppColors.cardDark : AppColors.card),
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : AppColors.softShadow,
        ),
        child: Row(
          children: [
            // Flag container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? AppColors.surfaceDark : AppColors.primarySoft),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _getLanguageEmoji(language.code),
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),

            const Gap(14),

            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nameAr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                    ),
                  ),
                  const Gap(3),
                  Text(
                    language.nameEn,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : (isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.borderDark : AppColors.border),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      PhosphorIcons.checkCircle(),
                      size: 18,
                      color: AppColors.primary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageEmoji(String code) {
    switch (code) {
      case 'ar':
        return '🇸🇦';
      case 'en':
        return '🇬🇧';
      case 'fa':
        return '🇮🇷';
      case 'ur':
        return '🇵🇰';
      case 'ku':
        return '🏴';
      default:
        return '🌍';
    }
  }
}
