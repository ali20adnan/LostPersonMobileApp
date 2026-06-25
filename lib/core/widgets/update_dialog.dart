import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_translator_app/core/utils/icon_direction.dart';

import '../../app/themes/app_colors.dart';
import '../../app/services/update_service.dart';

/// Elegant "update available" dialog shown by [UpdateService].
/// When [force] is true it cannot be dismissed (back button / barrier) —
/// the user must update to keep using the app.
class UpdateDialog extends StatelessWidget {
  final AppVersionInfo info;
  final bool force;
  final VoidCallback onUpdate;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.force,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lines = info.changelog
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return PopScope(
      canPop: !force,
      child: Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(PhosphorIcons.downloadSimple(),
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تحديث جديد متاح',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الإصدار ${info.latestVersion}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (lines.isNotEmpty) ...[
                    Text(
                      'ما الجديد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...lines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Icon(PhosphorIcons.checkCircle().ltr,
                                  size: 14, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                line,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark
                                      ? AppColors.textOnDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (force)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'هذا التحديث مطلوب للمتابعة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // ── Actions ──
                  Row(
                    children: [
                      if (!force) ...[
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: isDark
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                            child: const Text('لاحقاً'),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: force ? 1 : 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppColors.goldShadow,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: onUpdate,
                            icon: Icon(PhosphorIcons.downloadSimple(),
                                size: 18, color: Colors.white),
                            label: const Text(
                              'تحديث الآن',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
          ],
        ),
      ),
    );
  }
}
