import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../app/services/auth_service.dart';
import '../../../app/services/call_service.dart';
import '../../../app/services/socket_service.dart';
import '../../../app/services/unread_count_service.dart';
import '../../../data/models/chat_models.dart';
import '../../../data/repositories/conversation_repository.dart';
import 'conversations_controller.dart';

/// Controller for individual chat screen
class ChatController extends GetxController {
  final ConversationRepository _repo = ConversationRepository();
  final ImagePicker _picker = ImagePicker();

  final messages = <ChatMessage>[].obs;
  final isLoading = true.obs;
  final isSending = false.obs;
  final isTyping = false.obs; // remote user typing
  final typingUserName = ''.obs;

  /// Image picked but not yet sent. Held here so the user can add an optional
  /// caption (or remove it) before sending — mirrors the web composer, which
  /// stages the file and waits instead of uploading on selection.
  final stagedImage = Rxn<XFile>();

  final messageController = TextEditingController();
  final messageFocusNode = FocusNode();
  final itemScrollController = ItemScrollController();
  final itemPositionsListener = ItemPositionsListener.create();

  /// Whether the floating "new messages below" arrow is visible.
  final showScrollToBottom = false.obs;

  /// Live count of unseen messages below the viewport: seeded with the unread
  /// snapshot when the view anchors at the divider, incremented by socket
  /// arrivals while the user is scrolled up, reset once they reach the bottom.
  final newMessagesBelow = 0.obs;

  /// Whether the newest message is currently on screen (derived from
  /// [itemPositionsListener]); gates auto-scroll on incoming messages.
  bool _atBottom = true;

  late final int conversationId;
  ChatConversation? conversation;

  /// Snapshot of `conversation.unreadCount` captured before `markAsRead`,
  /// used to draw the "new messages" divider at the right boundary.
  int initialUnreadCount = 0;

  /// Index of the first unread message (= boundary above which the divider
  /// is drawn). Equals `messages.length` when there are no unread messages.
  int get unreadBoundary => messages.length - initialUnreadCount;

  int get currentUserId => Get.find<AuthService>().currentUser.value?.id ?? 0;

  /// Re-dial the other party from a tapped in-chat call-log card. Mirrors the
  /// header call button: 1:1 only, no-op if already in a call or unregistered.
  void redialFromCallLog() {
    final conv = conversation;
    if (conv == null || conv.isGroup) return;
    if (!Get.isRegistered<CallService>()) return;
    final others = conv.participants.where((p) => p.userId != currentUserId);
    if (others.isEmpty) return;
    final other = others.first;
    final call = Get.find<CallService>();
    if (call.inCall) return;
    call.startCall(
      conversationId: conv.id,
      toUserId: other.userId,
      callee: CallPeer(
        id: other.userId,
        fullName: other.fullName,
        avatarUrl: other.avatarUrl,
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    conversationId = Get.arguments?['conversationId'] as int? ?? 0;
    _loadConversation();
    _setupSocketListeners();
    messageFocusNode.addListener(_onMessageFocusChanged);
    itemPositionsListener.itemPositions.addListener(_onScrollPositionsChanged);
  }

  /// Track whether the newest message is on screen. The chat has no pixel
  /// ScrollController — visibility comes from the positioned-list's item
  /// positions: "at bottom" means the last real message (or the 1px sentinel
  /// after it) is among the visible items. Reaching the bottom clears the
  /// unseen counter and hides the floating arrow.
  void _onScrollPositionsChanged() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || messages.isEmpty) return;
    var maxIndex = -1;
    for (final p in positions) {
      if (p.index > maxIndex) maxIndex = p.index;
    }
    _atBottom = maxIndex >= messages.length - 1;
    if (_atBottom) {
      if (newMessagesBelow.value != 0) newMessagesBelow.value = 0;
      if (showScrollToBottom.value) showScrollToBottom.value = false;
    } else {
      final shouldShow = newMessagesBelow.value > 0;
      if (showScrollToBottom.value != shouldShow) {
        showScrollToBottom.value = shouldShow;
      }
    }
  }

  /// Jump to the newest message (floating-arrow tap). Hides the arrow
  /// immediately; the positions listener re-confirms once the scroll lands.
  void scrollToLatest() {
    showScrollToBottom.value = false;
    newMessagesBelow.value = 0;
    _scrollToBottom();
  }

  /// Scroll to the latest message whenever the input gains focus, so the
  /// keyboard doesn't end up covering the message the user was reading.
  void _onMessageFocusChanged() {
    if (messageFocusNode.hasFocus) _scrollToBottom();
  }

  /// Load conversation details and messages
  Future<void> _loadConversation() async {
    isLoading.value = true;
    try {
      conversation = await _repo.getConversation(conversationId);

      // Load message history
      final history = await _repo.getMessages(conversationId);

      // Compute the count of unread messages from the participant's
      // `myLastReadAt` timestamp — same approach the web client uses
      // (ChatWindow.tsx). Own messages are excluded so the divider only
      // separates messages the OTHER side sent. Must be set BEFORE
      // `messages.assignAll` because plain `int` writes after the Obx
      // rebuild won't retrigger it.
      final lastReadAt = conversation?.myLastReadAt;
      if (lastReadAt != null) {
        initialUnreadCount = history
            .where(
              (m) =>
                  m.senderId != currentUserId && m.sentAt.isAfter(lastReadAt),
            )
            .length;
      } else {
        initialUnreadCount = 0;
      }

      messages.assignAll(history);
      _scrollToInitialPosition();

      // Anchored above the fold with unread messages below → surface them via
      // the floating arrow right away. If everything actually fits on screen,
      // the positions listener fires after the jump and clears this again.
      if (initialUnreadCount > 0 && messages.isNotEmpty) {
        newMessagesBelow.value = initialUnreadCount.clamp(0, messages.length);
        showScrollToBottom.value = true;
        _atBottom = false;
      }

      // Join conversation room
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('joinConversation', {
          'conversationId': conversationId,
        });
      }

      // Mark messages as read
      _markAsRead();
    } catch (e) {
      debugPrint('ChatController: Error loading conversation - $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Unique listener key for this chat instance
  String get _listenerId => 'chat_$conversationId';

  /// Setup WebSocket listeners for this chat
  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    // Receive new message
    socket.on('newMessage', _listenerId, (data) {
      if (data is Map<String, dynamic>) {
        final message = ChatMessage.fromJson(data);
        if (message.conversationId == conversationId) {
          // Avoid duplicates (e.g. from image upload REST + socket broadcast)
          if (!messages.any((m) => m.id == message.id)) {
            messages.add(message);
            // Own messages and messages arriving while the user is already at
            // the bottom keep the familiar auto-scroll. While reading older
            // messages, don't yank the view down — surface the arrival via
            // the floating arrow + live counter instead.
            if (_atBottom || message.senderId == currentUserId) {
              _scrollToBottom();
            } else {
              newMessagesBelow.value++;
              showScrollToBottom.value = true;
            }
          }
          _markAsRead();
        }
      }
    });

    // Typing indicator
    socket.on('userTyping', _listenerId, (data) {
      if (data is Map<String, dynamic> &&
          data['conversationId'] == conversationId) {
        final userId = data['userId'] as int?;
        if (userId != null && userId != currentUserId) {
          isTyping.value = true;
          typingUserName.value = data['fullName'] as String? ?? '';
          // Auto-hide after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            isTyping.value = false;
          });
        }
      }
    });

    // Messages read confirmation
    socket.on('messagesRead', _listenerId, (data) {
      if (data is Map<String, dynamic> &&
          data['conversationId'] == conversationId) {
        // Could update read receipts UI here
      }
    });
  }

  /// Send the composed message via REST API (guaranteed delivery). Handles
  /// three cases with a single entry point (mirrors the web composer): a
  /// staged image with an optional caption, or a plain text message.
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    final image = stagedImage.value;
    if (text.isEmpty && image == null) return; // nothing to send

    isSending.value = true;
    _stopTypingNow();

    try {
      final sentMessage = image != null
          ? await _repo.uploadMessageImage(
              conversationId,
              image.path,
              content: text.isEmpty ? null : text,
            )
          : await _repo.sendMessage(conversationId, text);

      if (sentMessage != null) {
        // Clear the composer only on success so a failed send/upload lets the
        // user retry without re-typing or re-picking.
        messageController.clear();
        stagedImage.value = null;
        // Add locally if not already delivered via socket
        if (!messages.any((m) => m.id == sentMessage.id)) {
          messages.add(sentMessage);
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('ChatController: Error sending message - $e');
    } finally {
      isSending.value = false;
    }
  }

  /// Debounce timer that emits `isTyping: false` after the user stops typing.
  Timer? _typingStopTimer;
  bool _isTypingFlag = false;

  /// Send typing indicator. Emits `isTyping: true` immediately on the first
  /// keystroke and arms a 2s timer that emits `isTyping: false` once the user
  /// stops typing. Mirrors the web client (MessageInput.tsx) so the backend
  /// gets a clean start/stop pair and other participants see the indicator.
  void onTyping() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    if (!_isTypingFlag) {
      _isTypingFlag = true;
      socket.emit('typing', {
        'conversationId': conversationId,
        'isTyping': true,
      });
    }

    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 2), () {
      _isTypingFlag = false;
      socket.emit('typing', {
        'conversationId': conversationId,
        'isTyping': false,
      });
    });
  }

  /// Cancel the debounce and emit `isTyping: false` immediately. Used after
  /// sending a message and on dispose so the other side doesn't see a stale
  /// typing indicator.
  void _stopTypingNow() {
    _typingStopTimer?.cancel();
    _typingStopTimer = null;
    if (!_isTypingFlag) return;
    _isTypingFlag = false;
    if (!Get.isRegistered<SocketService>()) return;
    Get.find<SocketService>().emit('typing', {
      'conversationId': conversationId,
      'isTyping': false,
    });
  }

  /// Pick an image from the gallery and stage it for review. Nothing is
  /// uploaded here — the file waits in [stagedImage] until the user presses
  /// send (see [sendMessage]), optionally with a caption typed meanwhile.
  Future<void> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (file == null) return;
    stagedImage.value = file;
    messageFocusNode.requestFocus(); // invite an optional caption
  }

  /// Discard the staged image without sending.
  void clearStagedImage() => stagedImage.value = null;

  /// Mark messages as read
  void _markAsRead() {
    // Optimistic local updates so badges disappear immediately, without
    // waiting for the server's `messagesRead` round-trip.
    if (Get.isRegistered<ConversationsController>()) {
      Get.find<ConversationsController>().markConversationRead(conversationId);
    }
    if (Get.isRegistered<UnreadCountService>()) {
      Get.find<UnreadCountService>().refreshMessages();
    }
    if (!Get.isRegistered<SocketService>()) return;
    Get.find<SocketService>().emit('markAsRead', {
      'conversationId': conversationId,
    });
  }

  /// Scroll so the latest bubble is fully visible above the input/keyboard.
  ///
  /// Implementation note: the chat list renders an extra sentinel item at
  /// `index == messages.length` (a 1px SizedBox). We target THAT index with
  /// alignment 1.0, which reliably parks the sentinel at the viewport's
  /// trailing edge — leaving the last real bubble fully exposed above it.
  /// Targeting `messages.length - 1` directly is unreliable in
  /// ScrollablePositionedList when the bubble is taller than the remaining
  /// viewport.
  ///
  /// Two passes: first ~80ms after the new frame so the list has measured
  /// the new bubble; second ~350ms later so the keyboard's appearance
  /// animation finishes before the final scroll lands.
  void _scrollToBottom() {
    void doScroll() {
      if (messages.isEmpty || !itemScrollController.isAttached) return;
      itemScrollController.scrollTo(
        index: messages.length, // sentinel index (msgs.length + 1 items)
        alignment: 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 80), doScroll);
      Future.delayed(const Duration(milliseconds: 350), doScroll);
    });
  }

  /// Scroll to the position the user left off at: last read message at the
  /// bottom edge of the viewport, with unread messages just below.
  /// Falls back to scroll-to-bottom when there are no unread messages.
  void _scrollToInitialPosition() {
    final unread = initialUnreadCount;
    final total = messages.length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (total == 0 || !itemScrollController.isAttached) return;

      if (unread <= 0) {
        // Everything read — go to the latest message via the sentinel
        // (see _scrollToBottom for why we don't target total - 1 directly).
        itemScrollController.jumpTo(index: total, alignment: 1.0);
      } else if (unread >= total) {
        // Everything is unread (first time opening) — start from the top.
        itemScrollController.jumpTo(index: 0, alignment: 0.0);
      } else {
        // Land with the last read message at the bottom of the viewport;
        // unread messages will appear when the user scrolls down.
        itemScrollController.jumpTo(index: total - unread - 1, alignment: 1.0);
      }
    });
  }

  /// Get the other participant's name (for 1-to-1 chats)
  String get chatTitle {
    if (conversation == null) return 'محادثة';
    return conversation!.displayName(currentUserId);
  }

  @override
  void onClose() {
    itemPositionsListener.itemPositions.removeListener(
      _onScrollPositionsChanged,
    );
    messageFocusNode.removeListener(_onMessageFocusChanged);
    messageFocusNode.dispose();
    messageController.dispose();
    _stopTypingNow();
    if (Get.isRegistered<SocketService>()) {
      final socket = Get.find<SocketService>();
      socket.off('newMessage', _listenerId);
      socket.off('userTyping', _listenerId);
      socket.off('messagesRead', _listenerId);
    }
    super.onClose();
  }
}
