import 'package:flutter/material.dart';

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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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
    final color = widget.isRecording
        ? AppColors.recordActive
        : widget.isLoading
            ? AppColors.recordProcessing
            : AppColors.recordIdle;

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
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: widget.isRecording ? 20 : 10,
                    spreadRadius: widget.isRecording ? 5 : 0,
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      widget.isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: widget.size * 0.5,
                    ),
            ),
          );
        },
      ),
    );
  }
}
