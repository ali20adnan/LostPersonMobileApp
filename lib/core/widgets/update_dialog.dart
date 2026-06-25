import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:speech_translator_app/core/utils/icon_direction.dart';

import '../../app/themes/app_colors.dart';
import '../../app/services/update_service.dart';

/// Elegant "update available" dialog shown by [UpdateService].
/// On Android it downloads the APK in-app (with a progress bar) and opens the
/// installer; on iOS it redirects to the distribution page. When [force] is
/// true the dialog cannot be dismissed — the user must update.
class UpdateDialog extends StatefulWidget {
  final AppVersionInfo info;
  final bool force;

  /// Runs the update, reporting download progress (0..1). Returns an error
  /// message to display, or null on success.
  final Future<String?> Function(void Function(double progress) onProgress)
      onUpdate;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.force,
    required this.onUpdate,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _busy = false;
  double _progress = 0;
  String? _error;

  Future<void> _runUpdate() async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0;
    });

    final error = await widget.onUpdate((p) {
      if (mounted) setState(() => _progress = p);
    });

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lines = widget.info.changelog
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return PopScope(
      canPop: !widget.force && !_busy,
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
                    'الإصدار ${widget.info.latestVersion}',
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

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (widget.force && !_busy)
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

                  if (_busy)
                    _buildProgress(isDark)
                  else
                    _buildActions(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(bool isDark) {
    final pct = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    final downloading = Platform.isAndroid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          downloading ? 'جارٍ تنزيل التحديث... $pct%' : 'جارٍ الفتح...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        if (!widget.force) ...[
          Expanded(
            child: TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
              child: Text(_error != null ? 'إلغاء' : 'لاحقاً'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: widget.force ? 1 : 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.goldShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: _runUpdate,
              icon: Icon(PhosphorIcons.downloadSimple(),
                  size: 18, color: Colors.white),
              label: Text(
                _error != null ? 'إعادة المحاولة' : 'تحديث الآن',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
