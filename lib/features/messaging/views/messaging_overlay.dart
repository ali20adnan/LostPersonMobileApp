import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/conversations_controller.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/chat_models.dart';
import '../../notifications/controllers/notifications_controller.dart';
import 'new_chat_sheet.dart';

/// Wraps [child] in a backdrop blur for the glass variants. The light-theme
/// solid-blue chip skips the blur — otherwise the filter samples the lighter
/// page background at the rounded edges and produces a gradient sheen.
Widget _chipSurface({required bool solid, required Widget child}) {
  if (solid) return child;
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: child,
  );
}

/// Floating messaging button at top-right + Instagram-style slide-in panel
class MessagingOverlay extends StatelessWidget {
  /// White-glass chip with a white icon when floating over the dark gradient
  /// header; light chip with a navy icon over the light translator tab.
  final bool onDark;
  const MessagingOverlay({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConversationsController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<ConversationsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (Get.isRegistered<NotificationsController>()) {
            final nc = Get.find<NotificationsController>();
            if (nc.isOverlayOpen.value) nc.isOverlayOpen.value = false;
          }
          controller.toggleMessagingPanel();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            // Solid dark-navy fill (no transparency/blur) so the light map
            // never bleeds through as a white tint.
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: AppColors.bottomNavShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _chipSurface(
              solid: true,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    PhosphorIcons.chatCircle(),
                    color: AppColors.accent,
                    size: 22,
                  ),
                  if (controller.totalUnreadCount.value > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          controller.totalUnreadCount.value > 99
                              ? '99+'
                              : '${controller.totalUnreadCount.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Full-screen tap barrier that closes the messaging panel when tapping outside
class MessagingDismissBarrier extends StatelessWidget {
  const MessagingDismissBarrier({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConversationsController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<ConversationsController>();
    return Obx(() {
      if (!controller.isMessagingPanelOpen.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: GestureDetector(
          onTap: () => controller.isMessagingPanelOpen.value = false,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
      );
    });
  }
}

/// Instagram-style slide-in messaging panel from the right
class MessagingSlidePanel extends StatelessWidget {
  const MessagingSlidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConversationsController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<ConversationsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.85;

    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        top: 0,
        bottom: 0,
        right: controller.isMessagingPanelOpen.value ? 0 : -panelWidth,
        width: panelWidth,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: Material(
            color: isDark ? AppColors.backgroundDark : AppColors.background,
            child: Column(
              children: [
                SizedBox(height: topPadding),
                _PanelHeader(controller: controller),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
                _PanelSearchBar(controller: controller),
                Expanded(
                  child: _PanelConversationList(controller: controller),
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Panel header with title and new chat button
class _PanelHeader extends StatelessWidget {
  final ConversationsController controller;
  const _PanelHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => controller.isMessagingPanelOpen.value = false,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(PhosphorIcons.arrowRight(), size: 18),
            ),
            tooltip: 'إغلاق',
          ),
          const SizedBox(width: 4),
          Text(
            'المراسلات',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Obx(() {
            final count = controller.totalUnreadCount.value;
            if (count <= 0) return const SizedBox.shrink();
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count غير مقروءة',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              controller.isMessagingPanelOpen.value = false;
              _showNewChatDialog();
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(PhosphorIcons.pencilSimple(), size: 18, color: Colors.white),
            ),
            tooltip: 'محادثة جديدة',
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog() {
    Get.bottomSheet(const NewChatSheet(), isScrollControlled: true);
  }
}

/// Search bar inside the messaging panel
class _PanelSearchBar extends StatelessWidget {
  final ConversationsController controller;
  const _PanelSearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        decoration: InputDecoration(
          hintText: 'بحث في المحادثات...',
          prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
          filled: true,
          fillColor:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

/// Conversation list inside the messaging panel
class _PanelConversationList extends StatelessWidget {
  final ConversationsController controller;
  const _PanelConversationList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = controller.filteredConversations;
      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.2 : 1),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIcons.chatCircle(),
                    size: 40,
                    color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد محادثات',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ابدأ محادثة جديدة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshConversations,
        child: ListView.builder(
          itemCount: items.length,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, index) {
            return _PanelConversationTile(
              conversation: items[index],
              currentUserId: controller.currentUserId,
              onTap: () {
                controller.isMessagingPanelOpen.value = false;
                Get.toNamed('/chat', arguments: {
                  'conversationId': items[index].id,
                });
              },
            );
          },
        ),
      );
    });
  }
}

/// Single conversation tile for the slide-in panel
class _PanelConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final int currentUserId;
  final VoidCallback onTap;

  const _PanelConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = conversation.displayName(currentUserId);
    final resolvedAvatar = ApiConstants.resolveAvatarUrl(
        conversation.displayAvatarUrl(currentUserId));
    final lastMsg = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primarySoft,
                    image: resolvedAvatar != null
                        ? DecorationImage(
                            image: NetworkImage(resolvedAvatar),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: resolvedAvatar == null
                      ? Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0] : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (lastMsg != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          lastMsg.content ?? '\u{1F4F7} صورة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.normal,
                            color: hasUnread
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Time & badge
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastMsg != null)
                      Text(
                        _formatTime(lastMsg.sentAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: hasUnread
                              ? AppColors.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.35),
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    if (hasUnread) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return '${diff.inMinutes} د';
    if (diff.inDays < 1) return '${diff.inHours} س';
    if (diff.inDays < 7) return '${diff.inDays} ي';
    return '${dateTime.day}/${dateTime.month}';
  }
}
