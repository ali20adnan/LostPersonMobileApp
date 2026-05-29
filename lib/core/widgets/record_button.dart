import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../app/themes/app_colors.dart';

class RecordButton extends StatefulWidget {
  final bool isRecording;
  final bool isLoading;
  final VoidCallback onPressed;
  final double size;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
    this.isLoading = false,
    this.size = 80,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_rippleController.isAnimating) {
      _rippleController.repeat();
    } else if (!widget.isRecording && _rippleController.isAnimating) {
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  /// One ripple ring whose scale grows from 1.0 → 2.0 and fade goes 0.6 → 0
  /// over the ripple controller's cycle, offset by [phase] (0..1).
  Widget _buildRipple(double phase, Color color) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, _) {
        var t = (_rippleController.value + phase) % 1.0;
        final scale = 1.0 + t;
        final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.55;
        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.isRecording
        ? AppColors.warmGradient
        : widget.isLoading
            ? AppColors.heroGradient
            : AppColors.heroGradient;

    final glowColor =
        widget.isRecording ? AppColors.accent : AppColors.primary;

    final button = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isRecording ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: glowColor
                      .withValues(alpha: widget.isRecording ? 0.5 : 0.3),
                  blurRadius: widget.isRecording ? 28 : 16,
                  spreadRadius: widget.isRecording ? 6 : 2,
                ),
              ],
            ),
            child: widget.isLoading
                ? Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.white,
                      size: widget.size * 0.35,
                    ),
                  )
                : Icon(
                    widget.isRecording
                        ? PhosphorIcons.stop()
                        : PhosphorIcons.microphone(),
                    color: Colors.white,
                    size: widget.size * 0.4,
                  ),
          ),
        );
      },
    );

    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      child: SizedBox(
        width: widget.size * 2,
        height: widget.size * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isRecording) ...[
              _buildRipple(0.0, AppColors.accent),
              _buildRipple(0.5, AppColors.accent),
            ],
            button,
          ],
        ),
      ),
    );
  }
}
