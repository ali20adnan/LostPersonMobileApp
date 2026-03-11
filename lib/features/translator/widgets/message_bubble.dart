import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isOriginal; // true = right side (original), false = left side (translation)
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOriginal
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isOriginal ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isOriginal ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: Border.all(
            color: isOriginal
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.secondary.withValues(alpha: 0.3),
            width: 1,
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
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
