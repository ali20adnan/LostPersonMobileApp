import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/conversations_controller.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/chat_models.dart';

class ConversationsPage extends GetView<ConversationsController> {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المراسلات'),
        centerTitle: true,
        actions: [
          Obx(() {
            final count = controller.totalUnreadCount.value;
            return count > 0
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: 'بحث في المحادثات...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Conversation list
          Expanded(
            child: Obx(() {
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
                        'ابدأ محادثة جديدة بالضغط على +',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    return _ConversationTile(
                      conversation: items[index],
                      currentUserId: controller.currentUserId,
                      onTap: () => Get.toNamed('/chat', arguments: {
                        'conversationId': items[index].id,
                      }),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showNewChatDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
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
              child: Text('محادثة جديدة',
                  style: theme.textTheme.titleLarge),
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
                        backgroundImage: ApiConstants.resolveAvatarUrl(user.avatarUrl) != null
                            ? NetworkImage(ApiConstants.resolveAvatarUrl(user.avatarUrl)!)
                            : null,
                        child: ApiConstants.resolveAvatarUrl(user.avatarUrl) == null
                            ? Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0]
                                    : '?',
                                style: TextStyle(
                                  color:
                                      theme.colorScheme.onPrimaryContainer,
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

/// Single conversation tile widget
class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final int currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
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
          backgroundImage: resolvedAvatar != null
              ? NetworkImage(resolvedAvatar)
              : null,
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
                lastMsg.content ?? '📷 صورة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight:
                      hasUnread ? FontWeight.w600 : FontWeight.normal,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
