import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/group_chat_service.dart';

// Group chat service provider
final groupChatServiceProvider = Provider<GroupChatService>((ref) {
  return GroupChatService();
});

// Group participants provider
final groupParticipantsProvider = FutureProvider.family<List<String>, String>((ref, chatId) async {
  final groupChatService = ref.watch(groupChatServiceProvider);
  return await groupChatService.getGroupParticipants(chatId);
});

// Group chat state notifier
class GroupChatStateNotifier extends StateNotifier<AsyncValue<void>> {
  final GroupChatService _groupChatService;

  GroupChatStateNotifier(this._groupChatService) : super(const AsyncValue.data(null));

  Future<void> convertToGroupChat({
    required String chatId,
    required String groupName,
    required String groupDescription,
    required List<String> newParticipants,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _groupChatService.convertToGroupChat(
        chatId: chatId,
        groupName: groupName,
        groupDescription: groupDescription,
        newParticipants: newParticipants,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addParticipantsToGroup({
    required String chatId,
    required List<String> newParticipants,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _groupChatService.addParticipantsToGroup(
        chatId: chatId,
        newParticipants: newParticipants,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> removeParticipantsFromGroup({
    required String chatId,
    required List<String> participantsToRemove,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _groupChatService.removeParticipantsFromGroup(
        chatId: chatId,
        participantsToRemove: participantsToRemove,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateGroupInfo({
    required String chatId,
    String? groupName,
    String? groupDescription,
    String? groupAvatarUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _groupChatService.updateGroupInfo(
        chatId: chatId,
        groupName: groupName,
        groupDescription: groupDescription,
        groupAvatarUrl: groupAvatarUrl,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final groupChatStateProvider = StateNotifierProvider<GroupChatStateNotifier, AsyncValue<void>>((ref) {
  final groupChatService = ref.watch(groupChatServiceProvider);
  return GroupChatStateNotifier(groupChatService);
}); 