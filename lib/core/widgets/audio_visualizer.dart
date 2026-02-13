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
    this.barCount = 5,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          // Create varied heights for visual effect
          final random = Random(index);
          final baseHeight = amplitude * height;
          final variation = random.nextDouble() * 0.3 + 0.7;
          final barHeight = max(4.0, baseHeight * variation);

          return Container(
            width: 4,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
