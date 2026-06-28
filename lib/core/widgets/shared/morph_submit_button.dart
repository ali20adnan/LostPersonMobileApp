import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_motion.dart';

/// A submit button that morphs into a loading spinner while submitting,
/// then into a check-circle on success before the parent navigates away.
///
/// Pass [isSubmitting] and [isSuccess] from your controller's Rx values
/// (or any state source). [onPressed] is invoked only when both flags are
/// false (button idle).
class MorphSubmitButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSubmitting;
  final bool isSuccess;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  const MorphSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSuccess
        ? AppColors.success
        : (backgroundColor ?? AppColors.primary);
    final fg = foregroundColor ?? Colors.white;

    final isCollapsed = isSubmitting || isSuccess;
    final duration = AppMotion.respectReducedMotion(context, AppMotion.emphasized);

    return Center(
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.emphasizedCurve,
        width: isCollapsed ? height : double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(isCollapsed ? height / 2 : 16),
          boxShadow: AppColors.buttonShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isCollapsed ? null : onPressed,
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.respectReducedMotion(
                    context, AppMotion.standard),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: isSuccess
                    ? Icon(Icons.check_rounded,
                        key: const ValueKey('success'),
                        color: fg,
                        size: 28)
                    : isSubmitting
                        ? LoadingAnimationWidget.staggeredDotsWave(
                            key: const ValueKey('loading'),
                            color: fg,
                            size: 28,
                          )
                        : Row(
                            key: const ValueKey('idle'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, color: fg, size: 20),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                label,
                                style: TextStyle(
                                  color: fg,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
