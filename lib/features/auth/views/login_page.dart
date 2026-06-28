import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/widgets/islamic/dome_silhouette.dart';
import '../../../core/widgets/islamic/islamic_pattern_painter.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.surfaceGradient,
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
                  // ── Bismillah ────────────────────────────────
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.3, end: 0, duration: 400.ms),
                  const SizedBox(height: 20),

                  // ── Dome Silhouette ──────────────────────────
                  DomeSilhouette(
                    width: 180,
                    height: 140,
                    domeColor: isDark ? AppColors.accentLight : AppColors.accent,
                    minaretColor: isDark ? AppColors.accentLight : AppColors.accentDark,
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
                  const SizedBox(height: 28),

                  // ── Title ────────────────────────────────────
                  Column(
                    children: [
                      Text(
                        'الملاذ',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تسجيل الدخول للمتابعة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
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
                  const SizedBox(height: 36),

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
                            color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
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

                  // ── Username field ───────────────────────────
                  _InputField(
                    controller: controller.userNameController,
                    label: 'اسم المستخدم',
                    icon: PhosphorIcons.user(),
                    textInputAction: TextInputAction.next,
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 400.ms)
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          delay: 350.ms,
                          duration: 400.ms),
                  const SizedBox(height: 16),

                  // ── Password field ───────────────────────────
                  Obx(
                    () => _InputField(
                      controller: controller.passwordController,
                      label: 'كلمة المرور',
                      icon: PhosphorIcons.lock(),
                      obscureText: controller.obscurePassword.value,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => controller.login(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscurePassword.value
                              ? PhosphorIcons.eyeSlash()
                              : PhosphorIcons.eye(),
                          size: 20,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 400.ms)
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          delay: 450.ms,
                          duration: 400.ms),
                  const SizedBox(height: 28),

                  // ── Login button ─────────────────────────────
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
                                  controller.login();
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
                                    'تسجيل الدخول',
                                    key: ValueKey('text'),
                                    textAlign: TextAlign.center,
                                    // Cairo has tall descenders (ج/ل); give the
                                    // line box room so they aren't clipped.
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
                      .fadeIn(delay: 550.ms, duration: 400.ms)
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          delay: 550.ms,
                          duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
          ],
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
