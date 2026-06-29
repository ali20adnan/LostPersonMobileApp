import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/islamic/dome_silhouette.dart';
import '../../../core/widgets/islamic/islamic_pattern_painter.dart';
import '../controllers/force_password_change_controller.dart';

/// Forced password-change screen. Shown after signing in with a temporary
/// (default) password — the user must set a new password before entering the
/// app. Same idea as the web app's `/change-password` gate.
class ForcePasswordChangePage extends GetView<ForcePasswordChangeController> {
  const ForcePasswordChangePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      // The user can't dismiss this screen — they either change the password
      // or log out explicitly via the button below.
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient:
                isDark ? AppColors.darkGradient : AppColors.surfaceGradient,
          ),
          child: Stack(
            children: [
              // Islamic pattern background
              Positioned.fill(
                child: IslamicPatternOverlay(
                  opacity: isDark ? 0.03 : 0.04,
                  cellSize: 55,
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Dome Silhouette ──────────────────────────
                        DomeSilhouette(
                          width: 150,
                          height: 116,
                          domeColor:
                              isDark ? AppColors.accentLight : AppColors.accent,
                          minaretColor: isDark
                              ? AppColors.accentLight
                              : AppColors.accentDark,
                          showGlow: true,
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 24),

                        // ── Title ────────────────────────────────────
                        Column(
                          children: [
                            Text(
                              'تعيين كلمة مرور جديدة',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'يجب تغيير كلمة المرور قبل المتابعة',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 200.ms,
                                duration: 400.ms),
                        const SizedBox(height: 24),

                        // ── Security notice ──────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(PhosphorIcons.warningCircle(),
                                    color: AppColors.warning, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'كلمة المرور الحالية افتراضية ويجب تغييرها لأسباب أمنية',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 300.ms,
                                duration: 400.ms),
                        const SizedBox(height: 20),

                        // ── Error message ────────────────────────────
                        Obx(() {
                          if (controller.errorMessage.value.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      AppColors.error.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(PhosphorIcons.warningCircle(),
                                      color: AppColors.error, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    controller.errorMessage.value,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: -0.2, end: 0, duration: 300.ms);
                        }),

                        // ── New password field ───────────────────────
                        Obx(
                          () => _InputField(
                            controller: controller.newPasswordController,
                            label: 'كلمة المرور الجديدة',
                            icon: PhosphorIcons.lock(),
                            obscureText: controller.obscureNew.value,
                            textInputAction: TextInputAction.next,
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscureNew.value
                                    ? PhosphorIcons.eyeSlash()
                                    : PhosphorIcons.eye(),
                                size: 20,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              onPressed: controller.toggleNewVisibility,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms)
                            .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 400.ms,
                                duration: 400.ms),
                        const SizedBox(height: 16),

                        // ── Confirm password field ───────────────────
                        Obx(
                          () => _InputField(
                            controller: controller.confirmPasswordController,
                            label: 'تأكيد كلمة المرور',
                            icon: PhosphorIcons.lockKey(),
                            obscureText: controller.obscureConfirm.value,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => controller.submit(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscureConfirm.value
                                    ? PhosphorIcons.eyeSlash()
                                    : PhosphorIcons.eye(),
                                size: 20,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              onPressed: controller.toggleConfirmVisibility,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 400.ms)
                            .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 500.ms,
                                duration: 400.ms),
                        const SizedBox(height: 28),

                        // ── Submit button ────────────────────────────
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: controller.isLoading.value
                                    ? null
                                    : AppColors.accentGradient,
                                color: controller.isLoading.value
                                    ? AppColors.accent.withValues(alpha: 0.5)
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: controller.isLoading.value
                                    ? null
                                    : AppColors.goldShadow,
                              ),
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () {
                                        HapticFeedback.mediumImpact();
                                        controller.submit();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          key: ValueKey('loading'),
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation(
                                                Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'تغيير كلمة المرور والمتابعة',
                                          key: ValueKey('text'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.4,
                                            fontWeight: FontWeight.w700,
                                            leadingDistribution:
                                                TextLeadingDistribution.even,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 400.ms)
                            .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 600.ms,
                                duration: 400.ms),
                        const SizedBox(height: 12),

                        // ── Logout ───────────────────────────────────
                        TextButton.icon(
                          onPressed: controller.logout,
                          icon: Icon(PhosphorIcons.signOut(),
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                          label: Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      textDirection: TextDirection.ltr,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
