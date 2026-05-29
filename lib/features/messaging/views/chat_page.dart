import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../app/themes/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../controllers/chat_controller.dart';
import '../../../data/models/chat_models.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: _buildAppBar(context, isDark),
      body: Column(
        children: [
          // Messages list
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

              final msgs = controller.messages;
              if (msgs.isEmpty) {
                return _buildEmptyState(isDark);
              }

              final showUnreadDivider = controller.initialUnreadCount > 0 &&
                  controller.initialUnreadCount < msgs.length;
              final unreadBoundary = controller.unreadBoundary;

              return ScrollablePositionedList.builder(
                itemScrollController: controller.itemScrollController,
                itemPositionsListener: controller.itemPositionsListener,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // +1 sentinel item at the end so scrollTo can reliably land
                // past the last bubble (alignment 0.0 on the sentinel pins
                // it to the viewport top → bubble fully visible above).
                itemCount: msgs.length + 1,
                itemBuilder: (context, index) {
                  if (index == msgs.length) {
                    return const SizedBox(height: 1);
                  }
                  final msg = msgs[index];
                  final isMe = msg.senderId == controller.currentUserId;
                  final showDate = index == 0 ||
                      !_sameDay(msgs[index - 1].sentAt, msg.sentAt);
                  final showDivider =
                      showUnreadDivider && index == unreadBoundary;

                  return Column(
                    children: [
                      if (showDivider) _NewMessagesDivider(isDark: isDark),
                      if (showDate) _DateSeparator(date: msg.sentAt, isDark: isDark),
                      _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        isDark: isDark,
                      ),
                    ],
                  );
                },
              );
            }),
          ),

          // Typing indicator
          Obx(() {
            if (!controller.isTyping.value) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 16,
                    child: _TypingDots(),
                  ),
                  const Gap(8),
                  Text(
                    '${controller.typingUserName.value} يكتب...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Message input bar
          _buildInputBar(context, isDark),
        ],
      ),
    );
  }

  Widget _initialBadge(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(color: AppColors.primary),
      ),
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Obx(() {
        final isLoading = controller.isLoading.value;
        final displayName = controller.chatTitle;
        final initial = displayName.isNotEmpty ? displayName[0] : '?';
        final avatarUrl = controller.conversation == null
            ? null
            : ApiConstants.resolveAvatarUrl(
                controller.conversation!.displayAvatarUrl(controller.currentUserId));
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Hero(
              tag: 'conv-avatar-${controller.conversationId}',
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        avatarUrl == null ? AppColors.heroGradient : null,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _initialBadge(initial),
                        )
                      : _initialBadge(initial),
                ),
              ),
            ),
            const Gap(10),
            Flexible(
              child: isLoading
                  ? Text('جاري التحميل...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ))
                  : Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        );
      }),
      leading: IconButton(
        icon: Icon(PhosphorIcons.arrowRight(), color: Colors.white),
        onPressed: () => Get.back(),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: Icon(PhosphorIcons.chatText(),
                  size: 48, color: Colors.white),
            ),
            const Gap(24),
            Text(
              'ابدأ المحادثة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
              ),
            ),
            const Gap(8),
            Text(
              'أرسل رسالة للبدء',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image button
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: controller.pickAndSendImage,
                icon: Icon(PhosphorIcons.image(), color: AppColors.primary, size: 22),
                tooltip: 'إرسال صورة',
              ),
            ),
            const Gap(6),

            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
                  ),
                ),
                child: TextField(
                  controller: controller.messageController,
                  focusNode: controller.messageFocusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => controller.onTyping(),
                  style: TextStyle(
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const Gap(6),

            // Send button
            Obx(() => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: controller.isSending.value
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            controller.sendMessage();
                          },
                    icon: controller.isSending.value
                        ? LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white, size: 20)
                        : Icon(PhosphorIcons.paperPlaneTilt(),
                            color: Colors.white, size: 22),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerLeft : Alignment.centerRight;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.heroGradient : null,
          color: isMe
              ? null
              : (isDark ? AppColors.cardDark : AppColors.surfaceSunken),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? Radius.zero : const Radius.circular(18),
            bottomRight: isMe ? const Radius.circular(18) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender name
            if (!isMe && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Image
            if (message.imageUrl != null) _buildImage(context),

            // Text
            if (message.content != null && message.content!.isNotEmpty)
              Text(
                message.content!,
                style: TextStyle(
                  fontSize: 14,
                  color: isMe
                      ? Colors.white
                      : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                ),
              ),

            // Time
            const Gap(4),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                _formatTime(message.sentAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildImage(BuildContext context) {
    final resolvedUrl = ApiConstants.resolveUploadUrl(message.imageUrl);
    if (resolvedUrl == null) return const SizedBox.shrink();

    final heroTag = 'chat-image-${message.id}-$resolvedUrl';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => _openImageViewer(context, resolvedUrl, heroTag),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              resolvedUrl,
              width: 200,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 200,
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: AppColors.primary,
                    size: 28,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIcons.imageBroken(),
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String url, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _ImageViewerPage(url: url, heroTag: heroTag),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

/// Fullscreen image viewer with pinch-to-zoom
class _ImageViewerPage extends StatelessWidget {
  final String url;
  final String heroTag;

  const _ImageViewerPage({required this.url, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Icon(
                        PhosphorIcons.imageBroken(),
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'إغلاق',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Divider drawn between the last read message and the first unread message.
class _NewMessagesDivider extends StatelessWidget {
  final bool isDark;

  const _NewMessagesDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final lineColor = AppColors.primary.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: lineColor, thickness: 1, height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'رسائل جديدة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(child: Divider(color: lineColor, thickness: 1, height: 1)),
        ],
      ),
    );
  }
}

/// Date separator between messages
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const _DateSeparator({required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String text;

    if (_sameDay(date, now)) {
      text = 'اليوم';
    } else if (_sameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'أمس';
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Typing dots animation
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final size = 4.0 + (2.0 * (value < 0.5 ? value : 1.0 - value));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
