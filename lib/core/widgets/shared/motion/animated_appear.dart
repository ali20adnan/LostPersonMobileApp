import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/themes/app_motion.dart';

/// A single-shot fade + slight rise entrance for a widget.
///
/// Use to choreograph cold pages — stack several with cascading [delay]s
/// (e.g. 0, 80ms, 160ms, 240ms) to give a calm reveal.
class AnimatedAppear extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final Curve curve;

  const AnimatedAppear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.standard,
    this.offsetY = 12.0,
    this.curve = AppMotion.emphasizedCurve,
  });

  @override
  Widget build(BuildContext context) {
    final effective = AppMotion.respectReducedMotion(context, duration);
    if (effective == Duration.zero) return child;

    return child
        .animate(delay: delay)
        .fadeIn(duration: effective, curve: curve)
        .moveY(begin: offsetY, end: 0, duration: effective, curve: curve);
  }
}
