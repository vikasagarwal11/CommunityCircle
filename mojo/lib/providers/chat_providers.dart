import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/database_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/personal_message_model.dart';

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

// Unread count provider (for individual user tracking)
final userUnreadCountProvider = StreamProvider.family<int, String>((ref, communityId) {
  final chatService = ref.watch(chatServiceProvider);
  final userAsync = ref.watch(authNotifierProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(0);
      return chatService.getUserUnreadCount(communityId, user.id);
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

// Community members provider for read receipts
final communityMembersProvider = StreamProvider.family<List<UserModel>, String>((ref, communityId) {
  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.getCommunityMembers(communityId);
}); 

// Paginated messages notifier for infinite scroll with real-time updates
class PaginatedMessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final ChatService _chatService;
  final String communityId;
  final int pageSize;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  List<MessageModel> _messages = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoading = false;

  PaginatedMessagesNotifier(this._chatService, this.communityId, {this.pageSize = 20})
      : super(const AsyncValue.loading()) {
    _initializeMessagesStream();
  }

  List<MessageModel> get messages => _messages;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  void _initializeMessagesStream() {
    _messagesSubscription?.cancel();
    state = const AsyncValue.loading();
    
    _messagesSubscription = _chatService.getMessagesStream(communityId).listen(
      (messages) {
        _messages = messages;
        state = AsyncValue.data(List.from(_messages));
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
    
    // Add a timeout to prevent infinite loading
    Timer(const Duration(seconds: 10), () {
      if (state is AsyncLoading) {
        state = AsyncValue.error('Timeout loading messages', StackTrace.current);
      }
    });
  }

  Future<void> loadInitialMessages() async {
    state = const AsyncValue.loading();
    _messages = [];
    _lastDoc = null;
    _hasMore = true;
    _initializeMessagesStream();
  }

  Future<void> loadMoreMessages() async {
    if (!_hasMore || _isLoading) return;
    _isLoading = true;
    try {
      final docs = await _chatService.fetchMessagesPage(
        communityId: communityId,
        limit: pageSize,
        startAfterDoc: _lastDoc,
      );
      if (docs.isNotEmpty) {
        _lastDoc = docs.last;
        final newMessages = docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList();
        _messages.addAll(newMessages);
        state = AsyncValue.data(List.from(_messages));
        if (docs.length < pageSize) _hasMore = false;
      } else {
        _hasMore = false;
        state = AsyncValue.data(List.from(_messages));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    _isLoading = false;
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

final paginatedMessagesProvider = StateNotifierProvider.family<PaginatedMessagesNotifier, AsyncValue<List<MessageModel>>, String>((ref, communityId) {
  final chatService = ref.watch(chatServiceProvider);
  return PaginatedMessagesNotifier(chatService, communityId);
});

// Chat Hub providers
// Provider for last message in a community
final lastMessageProvider = FutureProvider.family<MessageModel?, String>((ref, communityId) async {
  final chatService = ref.watch(chatServiceProvider);
  try {
    return await chatService.getLastMessage(communityId);
  } catch (e) {
    return null;
  }
});

// Provider for unread message count in a community (simplified)
final unreadCountProvider = FutureProvider.family<int, String>((ref, communityId) async {
  final chatService = ref.watch(chatServiceProvider);
  try {
    return await chatService.getUnreadCount(communityId);
  } catch (e) {
    return 0;
  }
}); 

// Provider to get all personal chats for the current user
final personalChatsProvider = StreamProvider<List<PersonalChatModel>>((ref) {
  final userAsync = ref.watch(authNotifierProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      final userId = user.id;
      
      // Query personal chats where the user is a participant
      return FirebaseFirestore.instance
          .collection('personal_chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => PersonalChatModel.fromMap(doc.data(), doc.id))
                .toList();
          });
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// Provider to get messages for a given personal chat
final personalMessagesProvider = StreamProvider.family<List<PersonalMessageModel>, String>((ref, chatId) {
  if (chatId.isEmpty) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('personal_chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PersonalMessageModel.fromMap(doc.data(), doc.id)).toList())
      .handleError((error) {
        // Return empty list on error instead of throwing
        return <PersonalMessageModel>[];
      });
});

// Provider to start or get a personal chat between two users
final startPersonalChatProvider = FutureProvider.family<PersonalChatModel, String>((ref, otherUserId) async {
  final user = ref.read(authNotifierProvider).asData?.value;
  if (user == null) throw Exception('Not authenticated');
  final userId = user.id;
  final chatId = [userId, otherUserId]..sort();
  final chatDocId = chatId.join('_');
  final chatDoc = FirebaseFirestore.instance.collection('personal_chats').doc(chatDocId);
  
  print('DEBUG: Starting personal chat between $userId and $otherUserId');
  print('DEBUG: Chat document ID: $chatDocId');
  
  try {
    final docSnapshot = await chatDoc.get();
    print('DEBUG: Document exists: ${docSnapshot.exists}');
    
    if (docSnapshot.exists) {
      print('DEBUG: Returning existing chat');
      return PersonalChatModel.fromMap(docSnapshot.data()!, chatDocId);
    } else {
      print('DEBUG: Creating new chat document');
      // Create new chat
      final chatData = {
        'user1Id': userId,
        'user2Id': otherUserId,
        'participants': [userId, otherUserId],
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'user1Data': user.toMap(),
        'user2Data': {}, // Fill after fetching other user
      };
      print('DEBUG: Chat data to create: $chatData');
      await chatDoc.set(chatData);
      print('DEBUG: Chat document created successfully');
      
      // Optionally fetch and set user2Data
      print('DEBUG: Fetching other user data for $otherUserId');
      final otherUserSnap = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
      if (otherUserSnap.exists) {
        print('DEBUG: Other user found, updating chat document');
        await chatDoc.update({'user2Data': otherUserSnap.data()});
      } else {
        print('DEBUG: Other user not found');
      }
      
      final newDoc = await chatDoc.get();
      print('DEBUG: Returning newly created chat');
      return PersonalChatModel.fromMap(newDoc.data()!, chatDocId);
    }
  } catch (e, stackTrace) {
    print('DEBUG: Error in startPersonalChatProvider: $e');
    print('DEBUG: Stack trace: $stackTrace');
    rethrow;
  }
}); 

// Provider for suggested users (shared communities) or search (all users)
final userSearchOrSuggestedProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  final user = ref.read(authNotifierProvider).asData?.value;
  if (user == null) return [];
  final userId = user.id;

  if (query.isEmpty) {
    // SUGGESTED: users who share a community with me
    final myCommunities = user.communityIds;
    if (myCommunities.isEmpty) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('communityIds', arrayContainsAny: myCommunities)
        .limit(20)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .where((u) => u.id != userId)
        .toList();
  } else {
    // SEARCH: by displayName, email, or phoneNumber (merge results, dedupe)
    final usersRef = FirebaseFirestore.instance.collection('users');
    final futures = [
      usersRef
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .get(),
      usersRef
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .get(),
      usersRef
        .where('phoneNumber', isGreaterThanOrEqualTo: query)
        .where('phoneNumber', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .get(),
    ];
    final snapshots = await Future.wait(futures);
    final allUsers = <String, UserModel>{};
    for (final snap in snapshots) {
      for (final doc in snap.docs) {
        final u = UserModel.fromMap(doc.data());
        if (u.id != userId) {
          allUsers[u.id] = u;
        }
      }
    }
    return allUsers.values.take(20).toList();
  }
}); 