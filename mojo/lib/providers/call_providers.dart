import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/call_service.dart';

// Call service provider
final callServiceProvider = Provider<CallService>((ref) {
  return CallService();
});

// Active calls provider
final activeCallsProvider = StreamProvider.family<dynamic, String>((ref, userId) {
  final callService = ref.watch(callServiceProvider);
  return callService.getActiveCalls(userId);
});

// Call history provider
final callHistoryProvider = StreamProvider.family<dynamic, String>((ref, chatId) {
  final callService = ref.watch(callServiceProvider);
  return callService.getCallHistory(chatId);
});

// Call state notifier
class CallStateNotifier extends StateNotifier<AsyncValue<void>> {
  final CallService _callService;

  CallStateNotifier(this._callService) : super(const AsyncValue.data(null));

  Future<void> startCall({
    required String chatId,
    required String callType,
    required List<String> participants,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _callService.startCall(
        chatId: chatId,
        callType: callType,
        participants: participants,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> answerCall({
    required String callId,
    required String chatId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _callService.answerCall(
        callId: callId,
        chatId: chatId,
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
  }) async {
    state = const AsyncValue.loading();
    try {
      await _callService.endCall(
        callId: callId,
        chatId: chatId,
        duration: duration,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> declineCall({
    required String callId,
    required String chatId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _callService.declineCall(
        callId: callId,
        chatId: chatId,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final callStateProvider = StateNotifierProvider<CallStateNotifier, AsyncValue<void>>((ref) {
  final callService = ref.watch(callServiceProvider);
  return CallStateNotifier(callService);
}); 