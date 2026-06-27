import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import 'islamic_pattern_painter.dart';

/// Shared backdrop that gives every screen the login screen's identity:
/// a soft vertical gradient washed with a faint 8-pointed star pattern.
///
/// Mount it as the lowest layer of a screen and make the [Scaffold]
/// `backgroundColor: Colors.transparent` so headers, lists, and sheets
/// float above the same sacred surface the login uses. Adapts to dark mode
/// automatically (deep-navy gradient + lighter star strokes).
class SacredBackground extends StatelessWidget {
  final Widget child;

  /// Whether to paint the geometric star overlay. Disable on dense media
  /// screens (camera/map) where the pattern would compete with content.
  final bool patterned;

  const SacredBackground({
    super.key,
    required this.child,
    this.patterned = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkGradient : AppColors.surfaceGradient,
      ),
      child: patterned
          ? Stack(
              children: [
                Positioned.fill(
                  child: IslamicPatternOverlay(
                    opacity: isDark ? 0.03 : 0.04,
                    cellSize: 55,
                  ),
                ),
                child,
              ],
            )
          : child,
    );
  }
}
