import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/themes/app_colors.dart';

class AudioVisualizer extends StatelessWidget {
  final double amplitude;
  final int barCount;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.amplitude,
    this.barCount = 7,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          final random = Random(index);
          final baseHeight = amplitude * height;
          final variation = random.nextDouble() * 0.4 + 0.6;
          final barHeight = max(6.0, baseHeight * variation);

          // Gradient color per bar position
          final t = index / (barCount - 1);
          final color = Color.lerp(AppColors.primary, AppColors.secondary, t)!;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: 5,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
