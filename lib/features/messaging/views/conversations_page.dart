import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../app/themes/app_colors.dart';
import '../controllers/conversations_controller.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/chat_models.dart';

class ConversationsPage extends GetView<ConversationsController> {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                style: TextStyle(
                  color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'بحث في المحادثات...',
                  hintStyle: TextStyle(color: AppColors.textLight),
                  prefixIcon: const Icon(Iconsax.search_normal_1,
                      color: AppColors.primary, size: 20),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Conversation list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: AppColors.primary,
                    size: 40,
                  ),
                );
              }

              final items = controller.filteredConversations;
              if (items.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.refreshConversations,
                child: AnimationLimiter(
                  child: ListView.builder(
                    itemCount: items.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          horizontalOffset: 50,
                          child: FadeInAnimation(
                            child: _ConversationTile(
                              conversation: items[index],
                              currentUserId: controller.currentUserId,
                              isDark: isDark,
                              onTap: () => Get.toNamed('/chat', arguments: {
                                'conversationId': items[index].id,
                              }),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showNewChatDialog(context, isDark);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Iconsax.message_add_1, color: Colors.white),
        ),
      ).animate().scale(delay: 300.ms, duration: 400.ms),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(color: AppColors.primary),
      ),
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        'المراسلات',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Obx(() {
          final count = controller.totalUnreadCount.value;
          return count > 0
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$count غير مقروءة',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Iconsax.messages_3,
                size: 48, color: Colors.white),
          ),
          const Gap(20),
          Text(
            'لا توجد محادثات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          Text(
            'ابدأ محادثة جديدة بالضغط على +',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  void _showNewChatDialog(BuildContext context, bool isDark) {
    final searchCtrl = TextEditingController();
    final users = <ChatUser>[].obs;
    final isSearching = false.obs;

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Gap(8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('محادثة جديدة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                  ),
                ),
                child: TextField(
                  controller: searchCtrl,
                  style: TextStyle(
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
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
                    hintStyle: TextStyle(color: AppColors.textLight),
                    prefixIcon: const Icon(Iconsax.search_normal_1,
                        color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const Gap(8),
            Expanded(
              child: Obx(() {
                if (isSearching.value) {
                  return Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: AppColors.primary,
                      size: 30,
                    ),
                  );
                }
                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'ابحث عن مستخدم لبدء محادثة',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        backgroundImage: ApiConstants.resolveAvatarUrl(user.avatarUrl) != null
                            ? NetworkImage(ApiConstants.resolveAvatarUrl(user.avatarUrl)!)
                            : null,
                        child: ApiConstants.resolveAvatarUrl(user.avatarUrl) == null
                            ? Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0]
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(user.fullName,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                      subtitle: user.role != null
                          ? Text(user.role!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ))
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
  final bool isDark;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = conversation.displayName(currentUserId);
    final resolvedAvatar = ApiConstants.resolveAvatarUrl(
        conversation.displayAvatarUrl(currentUserId));
    final lastMsg = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorder),
        ),
        boxShadow: hasUnread
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: resolvedAvatar == null
                        ? AppColors.heroGradient
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.transparent,
                    backgroundImage: resolvedAvatar != null
                        ? NetworkImage(resolvedAvatar)
                        : null,
                    child: resolvedAvatar == null
                        ? Text(
                            displayName.isNotEmpty ? displayName[0] : '?',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const Gap(14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isDark
                              ? AppColors.textOnDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (lastMsg != null) ...[
                        const Gap(4),
                        Text(
                          lastMsg.content ?? '📷 صورة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: hasUnread
                                ? (isDark
                                    ? AppColors.textOnDark
                                    : AppColors.textPrimary)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Time & unread badge
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastMsg != null)
                      Text(
                        _formatTime(lastMsg.sentAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.textLight,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    if (hasUnread) ...[
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
