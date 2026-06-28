import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/themes/app_colors.dart';

/// Provides pre-built shimmer loading skeletons
/// for various content types across the app.
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
      highlightColor:
          isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight,
      child: child,
    );
  }

  /// Card skeleton (e.g. conversation card, incident card)
  static Widget card({double height = 100, double borderRadius = 20}) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Shimmer.fromColors(
        baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
        highlightColor:
            isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight,
        child: Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      );
    });
  }

  /// List of card skeletons
  static Widget cardList({int count = 4, double cardHeight = 100}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          count,
          (_) => card(height: cardHeight),
        ),
      ),
    );
  }

  /// Line skeleton (e.g. text line)
  static Widget line({
    double width = double.infinity,
    double height = 14,
    double borderRadius = 8,
  }) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Shimmer.fromColors(
        baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
        highlightColor:
            isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      );
    });
  }

  /// Circle skeleton (e.g. avatar)
  static Widget circle({double size = 48}) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Shimmer.fromColors(
        baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
        highlightColor:
            isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  /// Conversation item skeleton
  static Widget conversationItem() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Shimmer.fromColors(
        baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
        highlightColor:
            isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 36,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
