import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/themes/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isOriginal;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isOriginal,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeStr = DateFormat('HH:mm').format(timestamp);

    return Align(
      alignment: isOriginal ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isOriginal ? 60 : 12,
          right: isOriginal ? 12 : 60,
          bottom: 8,
          top: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isOriginal
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                    AppColors.primaryLight.withValues(alpha: isDark ? 0.15 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: isDark ? 0.2 : 0.1),
                    AppColors.secondary.withValues(alpha: isDark ? 0.1 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isOriginal ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isOriginal ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: Border.all(
            color: isOriginal
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.teal.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
