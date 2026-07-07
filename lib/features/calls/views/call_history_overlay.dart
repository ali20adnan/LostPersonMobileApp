import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../controllers/call_history_controller.dart';
import 'call_history_page.dart';

/// The 44×44 call-history bell button — placed beside the notification bell.
/// The dropdown itself is [CallHistoryPanel], rendered separately by the host
/// Stack so it spans the screen width (avoids the hit-test clipping the
/// notification overlay works around).
class CallHistoryButton extends StatelessWidget {
  const CallHistoryButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CallHistoryController>()) {
      return const SizedBox(width: 44, height: 44);
    }
    final controller = Get.find<CallHistoryController>();
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        controller.toggleOverlay();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: AppColors.bottomNavShadow,
        ),
        child: Icon(PhosphorIcons.phone(), color: AppColors.accent, size: 22),
      ),
    );
  }
}

/// Full-screen tap barrier that closes the call-history overlay.
class CallHistoryDismissBarrier extends StatelessWidget {
  const CallHistoryDismissBarrier({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CallHistoryController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<CallHistoryController>();
    return Obx(() {
      if (!controller.isOverlayOpen.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: GestureDetector(
          onTap: () => controller.isOverlayOpen.value = false,
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.transparent),
        ),
      );
    });
  }
}

/// The glassmorphic call-history dropdown. Sizes to its parent's width, so the
/// host should wrap it in a width-constrained Positioned (e.g. left/right: 12).
class CallHistoryPanel extends StatelessWidget {
  const CallHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CallHistoryController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<CallHistoryController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      if (!controller.isOverlayOpen.value) return const SizedBox.shrink();
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 440),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorder,
              ),
              boxShadow: AppColors.elevatedShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.phone(), size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'سجل المكالمات',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          controller.isOverlayOpen.value = false;
                          Get.to(() => const CallHistoryPage());
                        },
                        icon: Icon(PhosphorIcons.arrowLeft(), size: 14),
                        label: const Text('عرض الكل', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: Obx(() {
                    if (controller.isLoading.value && controller.entries.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (controller.entries.isEmpty) {
                      return _emptyState(theme, isDark);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                      physics: const ClampingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: controller.entries.length,
                      itemBuilder: (context, index) => CallHistoryTile(
                        entry: controller.entries[index],
                        isDark: isDark,
                        onTap: () => controller.redial(controller.entries[index]),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: -0.08, end: 0, duration: 250.ms, curve: Curves.easeOutCubic);
    });
  }

  Widget _emptyState(ThemeData theme, bool isDark) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: isDark ? 0.2 : 1),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIcons.phoneCall(),
                  size: 32, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد مكالمات',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

/// A single call-history row, reused by the overlay panel and the full page.
class CallHistoryTile extends StatelessWidget {
  final CallHistoryEntry entry;
  final bool isDark;
  final VoidCallback onTap;

  const CallHistoryTile({
    super.key,
    required this.entry,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiConstants.resolveAvatarUrl(entry.peerAvatarUrl);
    final v = _visuals();
    final time = _formatTime(entry.at);
    final subtitle = entry.outcome == 'completed'
        ? '$time · ${_formatDuration(entry.durationSeconds)}'
        : time;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: avatarUrl == null ? AppColors.heroGradient : null,
                ),
                child: avatarUrl != null
                    ? Image.network(avatarUrl, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _initial())
                    : _initial(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.peerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(v.icon, size: 14, color: v.color),
                        const SizedBox(width: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: entry.isMissedIncoming
                                ? AppColors.error
                                : AppColors.textLight,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIcons.phone(PhosphorIconsStyle.fill),
                  size: 18, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initial() => Center(
        child: Text(
          entry.peerName.isNotEmpty ? entry.peerName[0] : '؟',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );

  _Vis _visuals() {
    switch (entry.outcome) {
      case 'completed':
        return _Vis(
          entry.outgoing
              ? PhosphorIcons.phoneOutgoing()
              : PhosphorIcons.phoneIncoming(),
          AppColors.success,
        );
      case 'rejected':
        return _Vis(PhosphorIcons.phoneSlash(),
            entry.outgoing ? AppColors.textLight : AppColors.error);
      default:
        return _Vis(
          entry.outgoing ? PhosphorIcons.phoneOutgoing() : PhosphorIcons.phoneX(),
          entry.outgoing ? AppColors.textLight : AppColors.error,
        );
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return '$h:$m';
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'أمس $h:$m';
    }
    return '${dt.day}/${dt.month} $h:$m';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Vis {
  final IconData icon;
  final Color color;
  const _Vis(this.icon, this.color);
}
