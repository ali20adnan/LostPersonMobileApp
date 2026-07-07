import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/call_history_controller.dart';
import 'call_history_overlay.dart';

/// Full-screen comprehensive call history — dates, direction, outcome, duration.
class CallHistoryPage extends StatelessWidget {
  const CallHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.isRegistered<CallHistoryController>()
        ? Get.find<CallHistoryController>()
        : Get.put(CallHistoryController());

    // Refresh on open so the page is authoritative even if opened directly.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadCalls());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('سجل المكالمات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadCalls,
        child: Obx(() {
          if (controller.isLoading.value && controller.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.entries.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Icon(PhosphorIcons.phoneCall(),
                    size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'لا توجد مكالمات بعد',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: controller.entries.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: (isDark ? AppColors.dividerDark : AppColors.divider)
                  .withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final entry = controller.entries[index];
              return CallHistoryTile(
                entry: entry,
                isDark: isDark,
                onTap: () => controller.redial(entry),
              );
            },
          );
        }),
      ),
    );
  }
}
