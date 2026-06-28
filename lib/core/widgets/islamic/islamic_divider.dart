import 'package:flutter/material.dart';

/// An ornamental Islamic-style divider with a central diamond/dot
/// and decorative lines extending to both sides.
class IslamicDivider extends StatelessWidget {
  final Color? color;
  final double thickness;
  final double indent;
  final double endIndent;

  const IslamicDivider({
    super.key,
    this.color,
    this.thickness = 1.0,
    this.indent = 24,
    this.endIndent = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor =
        color ?? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1));
    final dotColor =
        color ?? (isDark ? const Color(0xFFFFD54F) : const Color(0xFFC49B00));

    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: thickness,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lineColor.withValues(alpha: 0), lineColor],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: thickness,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lineColor, lineColor.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
