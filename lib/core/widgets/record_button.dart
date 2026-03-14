import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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

    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
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
                    color: glowColor.withValues(alpha: widget.isRecording ? 0.5 : 0.3),
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
                          ? Iconsax.stop
                          : Iconsax.microphone,
                      color: Colors.white,
                      size: widget.size * 0.4,
                    ),
            ),
          );
        },
      ),
    );
  }
}
