import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/chat_models.dart';
import '../../../data/models/user_model.dart';
import '../controllers/conversations_controller.dart';

/// Bottomsheet for starting a new chat. Owns its own state and disposes
/// resources on tear-down — replaces the inline closures that previously
/// captured the caller's BuildContext and crashed with `_dependents.isEmpty`
/// when the keyboard was dismissed inside the sheet.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final _searchCtrl = TextEditingController();
  final _users = <ChatUser>[].obs;
  final _isSearching = false.obs;
  late final ConversationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ConversationsController>();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _users.close();
    _isSearching.close();
    super.dispose();
  }

  Future<void> _onQueryChanged(String val) async {
    if (val.length >= 2) {
      _isSearching.value = true;
      final results = await _controller.searchUsers(val);
      if (!mounted) return;
      _users.value = results;
      _isSearching.value = false;
    } else {
      _users.clear();
    }
  }

  Future<void> _onUserTap(ChatUser user) async {
    Get.back();
    final conv = await _controller.createConversation(user.id);
    if (conv != null) {
      Get.toNamed('/chat', arguments: {'conversationId': conv.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(PhosphorIcons.chatDots(),
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('محادثة جديدة',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'ابحث عن مستخدم...',
                prefixIcon:
                    Icon(PhosphorIcons.magnifyingGlass(), size: 20),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (_isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.magnifyingGlass(),
                          size: 40,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Text(
                        'ابحث عن مستخدم لبدء محادثة',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: _users.length,
                itemBuilder: (_, index) {
                  final user = _users[index];
                  final avatar =
                      ApiConstants.resolveAvatarUrl(user.avatarUrl);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage:
                          avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0]
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    title: Text(user.fullName),
                    subtitle: user.role != null
                        ? Text(roleDisplayArOf(user.role),
                            style: theme.textTheme.bodySmall)
                        : null,
                    onTap: () => _onUserTap(user),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
