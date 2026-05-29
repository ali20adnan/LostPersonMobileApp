import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/themes/app_motion.dart';

/// Wraps a form field (or any widget) and shakes it horizontally whenever
/// [trigger] increments. Pair with a controller that bumps a counter on
/// each failed validation pass so repeated submits re-trigger the shake.
class ShakeOnError extends StatelessWidget {
  final int trigger;
  final Widget child;

  const ShakeOnError({
    super.key,
    required this.trigger,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.respectReducedMotion(context, AppMotion.standard) ==
        Duration.zero) {
      return child;
    }
    // Use the trigger as the Animate key so a new trigger value rebuilds
    // the effect chain and runs the shake.
    return Animate(
      key: ValueKey(trigger),
      effects: const [
        ShakeEffect(
          duration: Duration(milliseconds: 350),
          hz: 4,
          offset: Offset(6, 0),
        ),
      ],
      child: child,
    );
  }
}
