import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../app/themes/app_motion.dart';

/// Wraps a list child widget with staggered slide + fade animation.
/// Use inside [AnimationLimiter] for coordinated list entrance.
class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final double verticalOffset;
  final double horizontalOffset;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.verticalOffset = 50.0,
    this.horizontalOffset = 0.0,
    this.duration = AppMotion.standard,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration,
      child: SlideAnimation(
        verticalOffset: verticalOffset,
        horizontalOffset: horizontalOffset,
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }
}
