import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/themes/app_colors.dart';

class TranslationDisplay extends StatefulWidget {
  final String text;
  final String label;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final bool isTranslation;

  const TranslationDisplay({
    super.key,
    required this.text,
    required this.label,
    this.backgroundColor,
    this.textStyle,
    this.isTranslation = false,
  });

  @override
  State<TranslationDisplay> createState() => _TranslationDisplayState();
}

class _TranslationDisplayState extends State<TranslationDisplay> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollDebounceTimer;

  @override
  void didUpdateWidget(TranslationDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text && widget.text.isNotEmpty) {
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 200), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && mounted) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            final currentScroll = _scrollController.offset;
            if (maxScroll - currentScroll <= 50 || currentScroll == 0) {
              _scrollController.animateTo(
                maxScroll,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmpty = widget.text.isEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              (isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.6)
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
          boxShadow: AppColors.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.isTranslation ? PhosphorIcons.translate() : PhosphorIcons.microphone(),
                  size: 16,
                  color: widget.isTranslation
                      ? AppColors.teal
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.isTranslation
                        ? AppColors.teal
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: isEmpty
                    ? Center(
                        child: Text(
                          widget.isTranslation
                              ? 'الترجمة ستظهر هنا...'
                              : 'ابدأ الحديث...',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textLight,
                          ),
                        ),
                      )
                    : SelectableText(
                        widget.text,
                        style: widget.textStyle ??
                            theme.textTheme.bodyLarge?.copyWith(
                              fontSize: widget.isTranslation ? 16 : 14,
                              height: 1.5,
                            ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
