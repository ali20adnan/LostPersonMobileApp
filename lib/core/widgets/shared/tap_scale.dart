import 'package:flutter/material.dart';

import '../../../app/themes/app_motion.dart';

/// Wraps any tappable widget with a subtle scale-down on press.
/// Use on cards, tiles, and pressable rows to add tactile feedback.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HitTestBehavior behavior;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _down() => setState(() => _pressed = true);
  void _up() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.respectReducedMotion(context, AppMotion.instant) ==
        Duration.zero;
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: widget.onTap == null ? null : (_) => _down(),
      onTapUp: widget.onTap == null ? null : (_) => _up(),
      onTapCancel: widget.onTap == null ? null : _up,
      child: AnimatedScale(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 120),
        curve: AppMotion.decelerate,
        scale: _pressed ? widget.scale : 1.0,
        child: widget.child,
      ),
    );
  }
}
