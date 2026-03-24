import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
    final isDark = controller.isDarkMode.value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowRight()),
            onPressed: () => Get.back(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Translation settings section
            _buildSectionTitle('إعدادات الترجمة', PhosphorIcons.translate(), isDark)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05),
            const Gap(10),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSettingTile(
                  isDark,
                  icon: PhosphorIcons.microphone(),
                  iconGradient: AppColors.heroGradient,
                  title: 'الكشف التلقائي للغة',
                  subtitle: 'كشف لغة المتحدث تلقائياً',
                  trailing: _buildSwitch(true),
                ),
                _buildDivider(isDark),
                _buildSettingTile(
                  isDark,
                  icon: PhosphorIcons.speakerHigh(),
                  iconGradient: AppColors.successGradient,
                  title: 'نطق الترجمة تلقائياً',
                  subtitle: 'تشغيل صوت الترجمة بعد اكتمالها',
                  trailing: _buildSwitch(false),
                ),
                _buildDivider(isDark),
                _buildSettingTile(
                  isDark,
                  icon: PhosphorIcons.floppyDisk(),
                  iconGradient: AppColors.heroGradient,
                  title: 'حفظ المحادثات تلقائياً',
                  subtitle: 'حفظ سجل الترجمة بشكل تلقائي',
                  trailing: _buildSwitch(true),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05),

            const Gap(24),

            // App settings section
            _buildSectionTitle('إعدادات التطبيق', PhosphorIcons.gear(), isDark)
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms)
                .slideX(begin: 0.05),
            const Gap(10),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSettingTile(
                  isDark,
                  icon: PhosphorIcons.moon(),
                  iconGradient: AppColors.darkGradient,
                  title: 'الوضع الداكن',
                  subtitle: isDark ? 'مفعل' : 'معطل',
                  trailing: _buildSwitch(isDark, onChanged: (v) {
                    HapticFeedback.lightImpact();
                    controller.toggleDarkMode(v);
                  }),
                ),
                _buildDivider(isDark),
                _buildSettingTile(
                  isDark,
                  icon: PhosphorIcons.bell(),
                  iconGradient: AppColors.warmGradient,
                  title: 'الإشعارات',
                  subtitle: controller.isNotificationsEnabled.value ? 'مفعل' : 'معطل',
                  trailing: _buildSwitch(controller.isNotificationsEnabled.value, onChanged: (v) {
                    HapticFeedback.lightImpact();
                    controller.toggleNotifications(v);
                  }),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05),

            const Gap(24),

            // About section
            _buildSectionTitle('حول التطبيق', PhosphorIcons.info(), isDark)
                .animate()
                .fadeIn(delay: 400.ms, duration: 300.ms)
                .slideX(begin: 0.05),
            const Gap(10),
            _buildSettingsCard(
              isDark,
              children: [
                _buildSettingTile(
                  isDark,
                  icon: PhosphorIcons.deviceMobile(),
                  iconGradient: AppColors.heroGradient,
                  title: 'إصدار التطبيق',
                  subtitle: '1.0.0',
                ),
                _buildDivider(isDark),
                _buildSettingTile(
                  isDark,
                  icon: PhosphorIcons.code(),
                  iconGradient: AppColors.accentGradient,
                  title: 'عن المطور',
                  subtitle: 'معلومات عن فريق التطوير',
                  trailing: Icon(PhosphorIcons.arrowLeft(),
                      size: 18, color: AppColors.textLight),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.05),

            const Gap(32),

            // App logo footer
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(PhosphorIcons.translate(),
                        color: Colors.white, size: 28),
                  ),
                  const Gap(10),
                  Text(
                    'مساعد الحرم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'مترجم صوتي فوري',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
            const Gap(24),
          ],
        ),
      ),
    );
    });
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const Gap(8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    bool isDark, {
    required IconData icon,
    required LinearGradient iconGradient,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: iconGradient,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.colors.first.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value, {ValueChanged<bool>? onChanged}) {
    return Switch(
      value: value,
      onChanged: onChanged ?? (_) {},
      activeColor: AppColors.primary,
      activeTrackColor: AppColors.primarySoft,
      inactiveThumbColor: AppColors.textLight,
      inactiveTrackColor: AppColors.surfaceSunken,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 58,
      color: isDark ? AppColors.dividerDark : AppColors.divider,
    );
  }
}
