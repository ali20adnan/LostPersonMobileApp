import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/themes/app_motion.dart';

/// GetX [CustomTransition] that wraps [SharedAxisTransition] (M3).
///
/// Use for sibling-level navigation (list → detail, sub-flow). Honors RTL
/// automatically because [SharedAxisTransition] flips X direction with
/// [Directionality].
class SharedAxisXTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      fillColor: Colors.transparent,
      child: child,
    );
  }
}

/// GetX [CustomTransition] using vertical shared-axis — top-of-stack feels
/// like alerts/notifications drawing up from below.
class SharedAxisYTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.vertical,
      fillColor: Colors.transparent,
      child: child,
    );
  }
}

/// GetX [CustomTransition] using [FadeThroughTransition] — best for swaps
/// between unrelated content (tab changes, login → home).
class FadeThroughGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      fillColor: Colors.transparent,
      child: child,
    );
  }
}

/// Wraps Material [OpenContainer] with project defaults (rounded card, no
/// elevation flash, theme-aware surface color). Use to grow a tappable
/// card/FAB into a full screen.
class OpenContainerCard extends StatelessWidget {
  final Widget closed;
  final Widget Function(BuildContext context, VoidCallback close) openBuilder;
  final BorderRadius? closedRadius;
  final Color? closedColor;
  final double closedElevation;

  const OpenContainerCard({
    super.key,
    required this.closed,
    required this.openBuilder,
    this.closedRadius,
    this.closedColor,
    this.closedElevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final radius = closedRadius ?? BorderRadius.circular(20);
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: AppMotion.emphasized,
      closedElevation: closedElevation,
      closedColor: closedColor ?? Theme.of(context).colorScheme.surface,
      closedShape: RoundedRectangleBorder(borderRadius: radius),
      openColor: Theme.of(context).scaffoldBackgroundColor,
      openElevation: 0,
      closedBuilder: (context, _) => closed,
      openBuilder: openBuilder,
    );
  }
}
