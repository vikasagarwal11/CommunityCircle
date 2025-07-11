import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../providers/auth_providers.dart';

// Chat service provider
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// Messages stream provider for a community
final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, communityId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getMessagesStream(communityId);
});

// Thread messages provider
final threadMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, threadId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getThreadMessages(threadId);
});

// Typing indicators provider
final typingUsersProvider = StreamProvider.family<List<String>, String>((ref, communityId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getTypingUsers(communityId);
});

// Unread count provider
final unreadCountProvider = StreamProvider.family<int, String>((ref, communityId) {
  final chatService = ref.watch(chatServiceProvider);
  final userAsync = ref.watch(authNotifierProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(0);
      return chatService.getUnreadCount(communityId, user.id);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

// Message search provider
final messageSearchProvider = StreamProvider.family<List<MessageModel>, Map<String, String>>((ref, params) {
  final chatService = ref.watch(chatServiceProvider);
  final communityId = params['communityId']!;
  final query = params['query']!;
  return chatService.searchMessages(communityId: communityId, query: query);
});

// Message stats provider
final messageStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, communityId) async {
  final chatService = ref.watch(chatServiceProvider);
  return await chatService.getMessageStats(communityId);
});

// Chat state notifier for managing chat actions
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatService _chatService;
  final Ref _ref;

  ChatNotifier(this._chatService, this._ref) : super(const AsyncValue.data(null));

  // Send message
  Future<void> sendMessage({
    required String communityId,
    required String text,
    String? mediaUrl,
    String? mediaType,
    String? threadId,
    List<String> mentions = const [],
  }) async {
    final userAsync = _ref.read(authNotifierProvider);
    final user = userAsync.value;
    if (user == null) throw Exception('User not authenticated');

    state = const AsyncValue.loading();

    try {
      await _chatService.sendMessage(
        communityId: communityId,
        userId: user.id,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        threadId: threadId,
        mentions: mentions,
      );

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Edit message
  Future<void> editMessage({
    required String messageId,
    required String newText,
    String? mediaUrl,
    String? mediaType,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _chatService.editMessage(
        messageId: messageId,
        newText: newText,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );

      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    state = const AsyncValue.loading();

    try {
      await _chatService.deleteMessage(messageId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Add reaction
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userAsync = _ref.read(authNotifierProvider);
    final user = userAsync.value;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _chatService.addReaction(
        messageId: messageId,
        emoji: emoji,
        userId: user.id,
      );
    } catch (e) {
      // Don't update state for reactions, just log error silently
    }
  }

  // Remove reaction
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userAsync = _ref.read(authNotifierProvider);
    final user = userAsync.value;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _chatService.removeReaction(
        messageId: messageId,
        emoji: emoji,
        userId: user.id,
      );
    } catch (e) {
      // Don't update state for reactions, just log error silently
    }
  }

  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    final userAsync = _ref.read(authNotifierProvider);
    final user = userAsync.value;
    if (user == null) return;

    try {
      await _chatService.markAsRead(
        messageId: messageId,
        userId: user.id,
      );
    } catch (e) {
      // Don't update state for read status, just log error silently
    }
  }

  // Set typing indicator
  Future<void> setTypingIndicator({
    required String communityId,
    required bool isTyping,
  }) async {
    final userAsync = _ref.read(authNotifierProvider);
    final user = userAsync.value;
    if (user == null) return;

    try {
      await _chatService.setTypingIndicator(
        communityId: communityId,
        userId: user.id,
        isTyping: isTyping,
      );
    } catch (e) {
      // Don't update state for typing indicators, just log error silently
    }
  }

  // Upload media
  Future<String?> uploadMedia({
    required String filePath,
    required String communityId,
    required String mediaType,
  }) async {
    try {
      return await _chatService.uploadMedia(
        filePath: filePath,
        communityId: communityId,
        mediaType: mediaType,
      );
    } catch (e) {
      // Return null on upload failure
      return null;
    }
  }
}

// Chat notifier provider
final chatNotifierProvider = StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(chatService, ref);
});

// Message actions state providers
final messageActionsProvider = StateProvider<Map<String, bool>>((ref) => {});

// Selected message for actions
final selectedMessageProvider = StateProvider<MessageModel?>((ref) => null);

// Message reply state
final replyToMessageProvider = StateProvider<MessageModel?>((ref) => null);

// Message search query
final messageSearchQueryProvider = StateProvider<String>((ref) => '');

// Media upload state
final mediaUploadStateProvider = StateProvider<AsyncValue<String?>>((ref) => const AsyncValue.data(null));

// Chat input state
final chatInputProvider = StateProvider<String>((ref) => '');

// Emoji picker state
final emojiPickerProvider = StateProvider<bool>((ref) => false);

// Message selection state (for multi-select)
final selectedMessagesProvider = StateProvider<Set<String>>((ref) => {});

// Chat filters
final chatFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'showReactions': true,
  'showThreads': true,
  'showMedia': true,
  'showMentions': true,
});

// Chat settings
final chatSettingsProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'autoScroll': true,
  'showTypingIndicator': true,
  'showReadReceipts': true,
  'messageSound': true,
  'vibration': true,
}); 