import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/shared_chat_service.dart';

// Shared chat service provider
final sharedChatServiceProvider = Provider<SharedChatService>((ref) {
  return SharedChatService();
});

// Active calls provider for any chat type
final activeCallsProvider = StreamProvider.family<dynamic, String>((ref, userId) {
  final sharedChatService = ref.watch(sharedChatServiceProvider);
  return sharedChatService.getActiveCalls(userId);
});

// Call history provider for any chat type
final callHistoryProvider = StreamProvider.family<dynamic, Map<String, String>>((ref, params) {
  final sharedChatService = ref.watch(sharedChatServiceProvider);
  final chatId = params['chatId']!;
  final chatType = params['chatType'] ?? 'personal';
  return sharedChatService.getCallHistory(chatId, chatType: chatType);
});

// Shared chat state notifier
class SharedChatStateNotifier extends StateNotifier<AsyncValue<void>> {
  final SharedChatService _sharedChatService;

  SharedChatStateNotifier(this._sharedChatService) : super(const AsyncValue.data(null));

  Future<void> startCall({
    required String chatId,
    required String callType,
    required List<String> participants,
    String chatType = 'personal',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _sharedChatService.startCall(
        chatId: chatId,
        callType: callType,
        participants: participants,
        chatType: chatType,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> answerCall({
    required String callId,
    required String chatId,
    String chatType = 'personal',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _sharedChatService.answerCall(
        callId: callId,
        chatId: chatId,
        chatType: chatType,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> endCall({
    required String callId,
    required String chatId,
    required int duration,
    String chatType = 'personal',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _sharedChatService.endCall(
        callId: callId,
        chatId: chatId,
        duration: duration,
        chatType: chatType,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> declineCall({
    required String callId,
    required String chatId,
    String chatType = 'personal',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _sharedChatService.declineCall(
        callId: callId,
        chatId: chatId,
        chatType: chatType,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    String chatType = 'personal',
    String? replyToMessageId,
    String? replyToText,
    Map<String, String>? reactions,
    List<String>? readBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _sharedChatService.sendMessage(
        chatId: chatId,
        text: text,
        chatType: chatType,
        replyToMessageId: replyToMessageId,
        replyToText: replyToText,
        reactions: reactions,
        readBy: readBy,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markMessageAsRead({
    required String messageId,
    required String chatId,
    String chatType = 'personal',
  }) async {
    try {
      await _sharedChatService.markMessageAsRead(
        messageId: messageId,
        chatId: chatId,
        chatType: chatType,
      );
    } catch (e) {
      // Don't update state for read receipts as they're not critical
    }
  }
}

final sharedChatStateProvider = StateNotifierProvider<SharedChatStateNotifier, AsyncValue<void>>((ref) {
  final sharedChatService = ref.watch(sharedChatServiceProvider);
  return SharedChatStateNotifier(sharedChatService);
}); 