import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/profile_controller.dart';
import '../../../core/constants/api_constants.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Obx(() {
          final user = controller.user.value;
          if (user == null) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: AppColors.primary,
                size: 40,
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refreshProfile,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, isDark),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildInfoCard(isDark)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.1),
                      const Gap(16),
                      _buildActionsCard(isDark)
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.1),
                      const Gap(16),
                      _buildLogoutButton(isDark)
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms)
                          .slideY(begin: 0.1),
                      const Gap(32),
                    ]),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final user = controller.user.value!;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Obx(() {
                final user = controller.user.value!;
                final avatarUrl = ApiConstants.resolveAvatarUrl(user.avatarUrl);
                
                return Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: controller.isUploadingAvatar.value
                      ? CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                      : ClipOval(
                          child: avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.primarySoft,
                                    child: LoadingAnimationWidget.staggeredDotsWave(
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => _buildPlaceholderAvatar(user),
                                )
                              : _buildPlaceholderAvatar(user),
                        ),
                );
              }),
              // Camera button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.pickAndUploadAvatar();
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    PhosphorIcons.camera(),
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          // Name
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const Gap(6),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              user.roleDisplayAr,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Temp password warning
          if (user.isTempPass) ...[
            const Gap(12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.warningCircle(),
                      color: AppColors.warningLight, size: 18),
                  const Gap(6),
                  const Text(
                    'كلمة مرور مؤقتة - يرجى تغييرها',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar(user) {
    return Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Text(
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    final user = controller.user.value!;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.user(), color: Colors.white, size: 18),
              ),
              const Gap(10),
              Text(
                'معلومات الحساب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(18),
          _buildInfoRow(
            isDark,
            icon: PhosphorIcons.userCircle(),
            label: 'اسم المستخدم',
            value: user.userName,
          ),
          if (user.accountExpiresAt != null) ...[
            Divider(
              height: 24,
              color: isDark ? AppColors.dividerDark : AppColors.divider,
            ),
            _buildInfoRow(
              isDark,
              icon: PhosphorIcons.timer(),
              label: 'انتهاء الحساب',
              value: _formatDate(user.accountExpiresAt!),
              valueColor: user.accountExpiresAt!.isBefore(DateTime.now())
                  ? AppColors.error
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.accentLight : AppColors.primary)
                .withValues(alpha: isDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18,
              color: isDark ? AppColors.accentLight : AppColors.primary),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const Gap(2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Settings row
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              onTap: () {
                HapticFeedback.lightImpact();
                Get.toNamed(AppRoutes.settings);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(PhosphorIcons.gear(), color: Colors.white, size: 20),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الإعدادات',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'تخصيص إعدادات التطبيق',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(PhosphorIcons.arrowLeft(),
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textLight, size: 20),
                  ],
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? AppColors.dividerDark : AppColors.divider,
          ),
          // Change password row
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              onTap: () {
                HapticFeedback.lightImpact();
                _showChangePasswordSheet(Get.context!);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(PhosphorIcons.lock(), color: Colors.white, size: 20),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تغيير كلمة المرور',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.textOnDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'تحديث كلمة مرور حسابك',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(PhosphorIcons.arrowLeft(),
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textLight, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            _showLogoutConfirmation(Get.context!);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIcons.signOut(), color: Colors.white, size: 22),
              Gap(10),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.signOut(), color: AppColors.error, size: 20),
              ),
              const Gap(10),
              Text('تسجيل الخروج',
                  style: TextStyle(
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  )),
            ],
          ),
          content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟',
              style: TextStyle(
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.logout();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text('تسجيل الخروج',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    controller.passwordError.value = '';
    controller.currentPasswordController.clear();
    controller.newPasswordController.clear();
    controller.confirmPasswordController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(PhosphorIcons.lock(), color: Colors.white, size: 20),
                    ),
                    const Gap(10),
                    Text(
                      'تغيير كلمة المرور',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                // Current password
                Obx(() => _buildPasswordField(
                      controller: controller.currentPasswordController,
                      obscure: controller.obscureCurrent.value,
                      toggleObscure: () => controller.obscureCurrent.toggle(),
                      label: 'كلمة المرور الحالية',
                      icon: PhosphorIcons.lock(),
                      isDark: isDark,
                    )),
                const Gap(16),
                // New password
                Obx(() => _buildPasswordField(
                      controller: controller.newPasswordController,
                      obscure: controller.obscureNew.value,
                      toggleObscure: () => controller.obscureNew.toggle(),
                      label: 'كلمة المرور الجديدة',
                      icon: PhosphorIcons.lock(),
                      isDark: isDark,
                      helperText: '6 أحرف على الأقل',
                    )),
                const Gap(16),
                // Confirm password
                Obx(() => _buildPasswordField(
                      controller: controller.confirmPasswordController,
                      obscure: controller.obscureConfirm.value,
                      toggleObscure: () => controller.obscureConfirm.toggle(),
                      label: 'تأكيد كلمة المرور الجديدة',
                      icon: PhosphorIcons.lock(),
                      isDark: isDark,
                    )),
                // Error message
                Obx(() {
                  if (controller.passwordError.value.isEmpty) {
                    return const Gap(20);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.warningCircle(),
                              color: AppColors.error, size: 18),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              controller.passwordError.value,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Gap(20),
                // Submit button
                Obx(() => Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: controller.isChangingPassword.value
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();
                                  final navigator = Navigator.of(ctx);
                                  final success =
                                      await controller.changePassword();
                                  if (success) navigator.pop();
                                },
                          child: Center(
                            child: controller.isChangingPassword.value
                                ? LoadingAnimationWidget.staggeredDotsWave(
                                    color: Colors.white, size: 22)
                                : const Text(
                                    'تغيير كلمة المرور',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggleObscure,
    required String label,
    required IconData icon,
    required bool isDark,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? PhosphorIcons.eyeSlash() : PhosphorIcons.eye(),
              color: AppColors.textLight,
              size: 20,
            ),
            onPressed: toggleObscure,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          helperText: helperText,
          helperStyle: TextStyle(color: AppColors.textLight, fontSize: 11),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
