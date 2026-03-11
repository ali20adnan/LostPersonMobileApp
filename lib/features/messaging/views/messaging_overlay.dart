import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/conversations_controller.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/chat_models.dart';
import '../../notifications/controllers/notifications_controller.dart';

/// Floating messaging button at top-right + Instagram-style slide-in panel
class MessagingOverlay extends StatelessWidget {
  const MessagingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConversationsController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<ConversationsController>();
    final theme = Theme.of(context);

    return Obx(() {
      return Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // Close notification overlay if open
            if (Get.isRegistered<NotificationsController>()) {
              final nc = Get.find<NotificationsController>();
              if (nc.isOverlayOpen.value) nc.isOverlayOpen.value = false;
            }
            controller.toggleMessagingPanel();
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    controller.isMessagingPanelOpen.value
                        ? Icons.chat_bubble
                        : Icons.chat_bubble_outline,
                    key: ValueKey(controller.isMessagingPanelOpen.value),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                // Unread badge
                if (controller.totalUnreadCount.value > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        controller.totalUnreadCount.value > 99
                            ? '99+'
                            : '${controller.totalUnreadCount.value}',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 10,
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
        child: Material(
          elevation: 16,
          shadowColor: Colors.black54,
          child: Container(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Fill status bar area with surface color
                Container(
                  height: topPadding,
                  color: theme.colorScheme.surface,
                ),
                // Header
                _PanelHeader(controller: controller),
                const Divider(height: 1),
                // Search bar
                _PanelSearchBar(controller: controller),
                // Conversation list
                Expanded(
                  child: _PanelConversationList(controller: controller),
                ),
                // Bottom safe area
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
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'إغلاق',
          ),
          const SizedBox(width: 4),
          Text(
            'المراسلات',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
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
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count غير مقروءة',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              controller.isMessagingPanelOpen.value = false;
              _showNewChatDialog(context, controller);
            },
            icon: const Icon(Icons.edit_square),
            tooltip: 'محادثة جديدة',
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(
      BuildContext context, ConversationsController controller) {
    final theme = Theme.of(context);
    final searchCtrl = TextEditingController();
    final users = <ChatUser>[].obs;
    final isSearching = false.obs;

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Text('محادثة جديدة', style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchCtrl,
                onChanged: (val) async {
                  if (val.length >= 2) {
                    isSearching.value = true;
                    users.value = await controller.searchUsers(val);
                    isSearching.value = false;
                  } else {
                    users.clear();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن مستخدم...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (isSearching.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'ابحث عن مستخدم لبدء محادثة',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage:
                            ApiConstants.resolveAvatarUrl(user.avatarUrl) !=
                                    null
                                ? NetworkImage(
                                    ApiConstants.resolveAvatarUrl(
                                        user.avatarUrl)!)
                                : null,
                        child:
                            ApiConstants.resolveAvatarUrl(user.avatarUrl) ==
                                    null
                                ? Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0]
                                        : '?',
                                    style: TextStyle(
                                      color: theme
                                          .colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                : null,
                      ),
                      title: Text(user.fullName),
                      subtitle: user.role != null
                          ? Text(user.role!,
                              style: theme.textTheme.bodySmall)
                          : null,
                      onTap: () async {
                        Get.back();
                        final conv =
                            await controller.createConversation(user.id);
                        if (conv != null) {
                          Get.toNamed('/chat',
                              arguments: {'conversationId': conv.id});
                        }
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
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
          prefixIcon: const Icon(Icons.search),
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
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'لا توجد محادثات',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ابدأ محادثة جديدة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage:
              resolvedAvatar != null ? NetworkImage(resolvedAvatar) : null,
          child: resolvedAvatar == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0] : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: lastMsg != null
            ? Text(
                lastMsg.content ?? '\u{1F4F7} صورة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  color: hasUnread
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outline,
                ),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMsg != null)
              Text(
                _formatTime(lastMsg.sentAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: hasUnread
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
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
