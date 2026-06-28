import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';

/// A premium glassmorphic card with optional gradient border,
/// blur backdrop, and soft shadow.
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Gradient? gradient;
  final bool enableGlass;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.gradient,
    this.enableGlass = false,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (enableGlass
                ? (isDark ? AppColors.glassDark : AppColors.glassWhite)
                : (isDark ? AppColors.cardDark : AppColors.card))
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: enableGlass
              ? (isDark ? AppColors.glassBorderDark : AppColors.glassBorder)
              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
          width: 1,
        ),
        boxShadow: boxShadow ?? (enableGlass ? null : AppColors.cardShadow),
      ),
      child: enableGlass
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppColors.glassBlur,
                  sigmaY: AppColors.glassBlur,
                ),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
