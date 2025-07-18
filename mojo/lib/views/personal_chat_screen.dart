import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/database_providers.dart';
import '../providers/user_providers.dart';
import '../providers/call_providers.dart';
import '../providers/group_chat_providers.dart';
import '../models/personal_message_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/read_receipt_widget.dart';
import '../widgets/swipe_to_reply_personal_message.dart';
import 'dart:async';

// Debounce utility for typing indicator
class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class PersonalChatScreen extends HookConsumerWidget {
  final String otherUserId;
  
  const PersonalChatScreen({
    super.key,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final otherUserAsync = ref.watch(userByIdProvider(otherUserId));
    final personalChatAsync = ref.watch(startPersonalChatProvider(otherUserId));
    final personalMessagesAsync = ref.watch(personalMessagesProvider(personalChatAsync.value?.id ?? ''));
    
    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final isTyping = useState(false);
    final replyToMessage = useState<PersonalMessageModel?>(null);

    // Debouncer for typing indicator
    final debouncer = useMemoized(() => Debouncer(milliseconds: 500));
    useEffect(() => debouncer.dispose, []);

    // Auto-scroll to bottom when new messages arrive
    useEffect(() {
      if (personalMessagesAsync.hasValue && personalMessagesAsync.value!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      return null;
    }, [personalMessagesAsync]);

    // Auto-mark messages as read when viewed
    useEffect(() {
      final messages = personalMessagesAsync.value;
      final currentUser = userAsync.value;
      
      if (messages != null && currentUser != null && messages.isNotEmpty) {
        // Mark visible messages as read
        final unreadMessages = messages.where((message) => 
          message.senderId != currentUser.id && 
          !message.readBy.contains(currentUser.id)
        ).toList();
        
        if (unreadMessages.isNotEmpty) {
          // Mark messages as read with a slight delay to avoid spam
          Future.delayed(const Duration(milliseconds: 500), () {
            for (final message in unreadMessages) {
              _markMessageAsRead(ref, message.id, personalChatAsync.value?.id ?? '');
            }
          });
        }
      }
      return null;
    }, [personalMessagesAsync, userAsync]);

    // Handle typing indicator
    useEffect(() {
      if (isTyping.value) {
        _setTypingIndicator(ref, personalChatAsync.value?.id ?? '', true);
        final timer = Timer(const Duration(seconds: 3), () {
          isTyping.value = false;
          _setTypingIndicator(ref, personalChatAsync.value?.id ?? '', false);
        });
        return timer.cancel;
      }
      return null;
    }, [isTyping.value]);

    return Scaffold(
      appBar: AppBar(
        title: otherUserAsync.when(
          data: (otherUser) => Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: otherUser?.profilePictureUrl != null 
                    ? NetworkImage(otherUser!.profilePictureUrl!)
                    : null,
                child: otherUser?.profilePictureUrl == null
                    ? Text(
                        otherUser?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser?.displayName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      otherUser?.isOnline == true ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('User'),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final personalChatAsync = ref.read(startPersonalChatProvider(otherUserId));
              personalChatAsync.when(
                data: (chat) {
                  if (chat != null) {
                    NavigationService.navigateToMessageSearch(
                      chatId: chat.id,
                      otherUserId: otherUserId,
                      otherUserName: otherUserAsync.value?.displayName ?? 'User',
                    );
                  } else {
                    NavigationService.showSnackBar(message: 'Chat not ready. Please try again.');
                  }
                },
                loading: () => NavigationService.showSnackBar(message: 'Loading chat...'),
                error: (_, __) => NavigationService.showSnackBar(message: 'Error loading chat'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions(context, ref, otherUserAsync);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply preview
          if (replyToMessage.value != null) _buildReplyPreview(context, replyToMessage.value!, () {
            replyToMessage.value = null;
          }),
          
          // Messages list
          Expanded(
            child: personalMessagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwnMessage = userAsync.value?.id == message.senderId;
                    
                    return SwipeToReplyPersonalMessage(
                      message: message,
                      onReply: () {
                        replyToMessage.value = message;
                      },
                      child: _buildMessageTile(
                        context,
                        message,
                        isOwnMessage,
                        ref,
                        otherUserAsync,
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) {
                // Show previous data if available, otherwise show error
                final previousData = personalMessagesAsync.value;
                if (previousData != null && previousData.isNotEmpty) {
                  return ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: previousData.length,
                    itemBuilder: (context, index) {
                      final message = previousData[index];
                      final isOwnMessage = userAsync.value?.id == message.senderId;
                      
                      return SwipeToReplyPersonalMessage(
                        message: message,
                        onReply: () {
                          replyToMessage.value = message;
                        },
                        child: _buildMessageTile(
                          context,
                          message,
                          isOwnMessage,
                          ref,
                          otherUserAsync,
                        ),
                      );
                    },
                  );
                }
                return CustomErrorWidget(
                  message: 'Error loading messages: $error',
                );
              },
            ),
          ),
          
          // Chat input
          if (personalChatAsync.hasValue)
            _buildChatInput(
              context,
              ref,
              messageController,
              personalChatAsync.value!.id,
              replyToMessage.value,
              () => replyToMessage.value = null,
              () => _showAttachmentOptions(context, ref),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Start the conversation by sending a message!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(
    BuildContext context,
    PersonalMessageModel message,
    bool isOwnMessage,
    WidgetRef ref,
    AsyncValue<UserModel?> otherUserAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            otherUserAsync.when(
              data: (otherUser) => CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                backgroundImage: otherUser?.profilePictureUrl != null 
                    ? NetworkImage(otherUser!.profilePictureUrl!)
                    : null,
                child: otherUser?.profilePictureUrl == null
                    ? Text(
                        otherUser?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              loading: () => CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  'U',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                  decoration: BoxDecoration(
                    color: isOwnMessage 
                        ? colorScheme.primary 
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOwnMessage 
                          ? colorScheme.primary 
                          : colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reply to message
                      if (message.replyToText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message.replyToText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      
                      // Message text
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isOwnMessage 
                              ? Colors.white 
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Message metadata
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                                             if (isOwnMessage) ...[
                         const SizedBox(width: 4),
                         Icon(
                           message.readBy.length > 1 
                               ? Icons.done_all 
                               : Icons.done,
                           size: 12,
                           color: message.readBy.length > 1 
                               ? colorScheme.primary 
                               : colorScheme.onSurface.withOpacity(0.5),
                         ),
                       ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, PersonalMessageModel replyTo, VoidCallback onCancel) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              'Replying to: ${replyTo.text}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(
    BuildContext context,
    WidgetRef ref,
    TextEditingController messageController,
    String chatId,
    PersonalMessageModel? replyToMessage,
    VoidCallback onCancelReply,
    VoidCallback onAttachmentPressed,
  ) {
    final hasText = useState(false);
    
    // Listen to text changes to update button state
    useEffect(() {
      void onTextChanged() {
        hasText.value = messageController.text.trim().isNotEmpty;
      }
      
      messageController.addListener(onTextChanged);
      return () => messageController.removeListener(onTextChanged);
    }, [messageController]);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: onAttachmentPressed,
          ),
          
          // Text input
          Expanded(
            child: TextField(
              controller: messageController,
              onChanged: (value) {
                hasText.value = value.trim().isNotEmpty;
                // Typing indicator logic can be added here
              },
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          
          // Send button
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: hasText.value ? () async {
              print('DEBUG: Send button pressed');
              print('DEBUG: Message text: "${messageController.text.trim()}"');
              
              // Clear input immediately for better UX
              final messageText = messageController.text.trim();
              messageController.clear();
              hasText.value = false;
              onCancelReply();
              
              // Send message with slight delay to prevent UI flicker
              await Future.delayed(const Duration(milliseconds: 50));
              _sendMessage(ref, chatId, messageText, replyToMessage);
            } : null,
            style: IconButton.styleFrom(
              backgroundColor: hasText.value 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              foregroundColor: hasText.value 
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

    void _sendMessage(
    WidgetRef ref,
    String chatId,
    String text,
    PersonalMessageModel? replyToMessage,
  ) async {
    print('DEBUG: _sendMessage called with text: "$text"');
    print('DEBUG: chatId: $chatId');
    print('DEBUG: otherUserId: $otherUserId');
    
    if (chatId.isEmpty) {
      print('DEBUG: ChatId is empty, cannot send message');
      NavigationService.showSnackBar(message: 'Chat not ready. Please try again.');
      return;
    }
    
    try {
      final user = ref.read(authNotifierProvider).asData?.value;
      print('DEBUG: Current user: ${user?.id}');
      
      if (user == null) {
        print('DEBUG: User is null, returning');
        NavigationService.showSnackBar(message: 'Please log in to send messages.');
        return;
      }

      final messageData = {
        'senderId': user.id,
        'receiverId': otherUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [user.id],
        'reactions': {},
        'replyToMessageId': replyToMessage?.id,
        'replyToText': replyToMessage?.text,
      };
      
      print('DEBUG: Message data to send: $messageData');
      print('DEBUG: Adding message to Firestore...');

      // Add message to Firestore
      await FirebaseFirestore.instance
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);
      
      print('DEBUG: Message added successfully to Firestore');

      // Update last message in chat (with error handling)
      try {
        print('DEBUG: Updating chat document...');
        await FirebaseFirestore.instance
            .collection('personal_chats')
            .doc(chatId)
            .update({
          'lastMessage': messageData,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
        print('DEBUG: Chat document updated successfully');
      } catch (updateError) {
        print('DEBUG: Error updating chat document: $updateError');
        // Don't show error to user since message was sent successfully
      }

    } catch (e) {
      print('DEBUG: Error sending message: $e');
      NavigationService.showSnackBar(
        message: 'Failed to send message. Please try again.',
      );
    }
  }

  void _markMessageAsRead(WidgetRef ref, String messageId, String chatId) async {
    try {
      final user = ref.read(authNotifierProvider).asData?.value;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([user.id]),
      });
    } catch (e) {
      // Silently handle read receipt errors
    }
  }

  void _setTypingIndicator(WidgetRef ref, String chatId, bool isTyping) async {
    try {
      final user = ref.read(authNotifierProvider).asData?.value;
      if (user == null) return;

      if (isTyping) {
        await FirebaseFirestore.instance
            .collection('personal_chats')
            .doc(chatId)
            .collection('typing')
            .doc(user.id)
            .set({
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('personal_chats')
            .doc(chatId)
            .collection('typing')
            .doc(user.id)
            .delete();
      }
    } catch (e) {
      // Silently handle typing indicator errors
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}';
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  void _showChatOptions(BuildContext context, WidgetRef ref, AsyncValue<UserModel?> otherUserAsync) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Call options
            ListTile(
              leading: const Icon(Icons.call),
              title: const Text('Audio Call'),
              onTap: () {
                NavigationService.goBack();
                _startCall(context, ref, 'audio');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video Call'),
              onTap: () {
                NavigationService.goBack();
                _startCall(context, ref, 'video');
              },
            ),
            const Divider(),
            // Group chat options
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Add to Group'),
              onTap: () {
                NavigationService.goBack();
                _showAddToGroupOptions(context, ref);
              },
            ),
            const Divider(),
            // Other options
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Messages'),
              onTap: () {
                NavigationService.goBack();
                final personalChatAsync = ref.read(startPersonalChatProvider(otherUserId));
                personalChatAsync.when(
                  data: (chat) {
                    if (chat != null) {
                      NavigationService.navigateToMessageSearch(
                        chatId: chat.id,
                        otherUserId: otherUserId,
                        otherUserName: otherUserAsync.value?.displayName ?? 'User',
                      );
                    } else {
                      NavigationService.showSnackBar(message: 'Chat not ready. Please try again.');
                    }
                  },
                  loading: () => NavigationService.showSnackBar(message: 'Loading chat...'),
                  error: (_, __) => NavigationService.showSnackBar(message: 'Error loading chat'),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                NavigationService.goBack();
                otherUserAsync.when(
                  data: (user) {
                    if (user != null) {
                      // TODO: Navigate to user profile
                      NavigationService.showSnackBar(message: 'Profile view coming soon!');
                    }
                  },
                  loading: () => NavigationService.showSnackBar(message: 'Loading...'),
                  error: (_, __) => NavigationService.showSnackBar(message: 'Error loading user'),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Block functionality coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startCall(BuildContext context, WidgetRef ref, String callType) async {
    try {
      final user = ref.read(authNotifierProvider).asData?.value;
      if (user == null) {
        NavigationService.showSnackBar(message: 'Please log in to make calls.');
        return;
      }

      final personalChatAsync = ref.read(startPersonalChatProvider(otherUserId));
      personalChatAsync.when(
        data: (chat) async {
          if (chat != null) {
            // Start the call
            await ref.read(callStateProvider.notifier).startCall(
              chatId: chat.id,
              callType: callType,
              participants: [user.id, otherUserId],
            );
            
            // Navigate to call screen
            NavigationService.navigateToCall(
              callId: '${chat.id}_${DateTime.now().millisecondsSinceEpoch}',
              chatId: chat.id,
              callType: callType,
            );
          } else {
            NavigationService.showSnackBar(message: 'Chat not ready. Please try again.');
          }
        },
        loading: () => NavigationService.showSnackBar(message: 'Loading chat...'),
        error: (_, __) => NavigationService.showSnackBar(message: 'Error loading chat'),
      );
    } catch (e) {
      NavigationService.showSnackBar(
        message: 'Error starting call: $e',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  void _showAddToGroupOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create Group Chat'),
              subtitle: const Text('Convert this chat to a group and add more people'),
              onTap: () {
                NavigationService.goBack();
                _navigateToAddParticipants(context, ref, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add to Existing Group'),
              subtitle: const Text('Add this person to an existing group chat'),
              onTap: () {
                NavigationService.goBack();
                _navigateToGroupSelection(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddParticipants(BuildContext context, WidgetRef ref, bool isConvertingToGroup) {
    final personalChatAsync = ref.read(startPersonalChatProvider(otherUserId));
    personalChatAsync.when(
      data: (chat) {
        if (chat != null) {
          NavigationService.navigateToAddParticipants(
            chatId: chat.id,
            isConvertingToGroup: isConvertingToGroup,
            currentGroupName: isConvertingToGroup ? 'New Group' : null,
          );
        } else {
          NavigationService.showSnackBar(message: 'Chat not ready. Please try again.');
        }
      },
      loading: () => NavigationService.showSnackBar(message: 'Loading chat...'),
      error: (_, __) => NavigationService.showSnackBar(message: 'Error loading chat'),
    );
  }

  void _navigateToGroupSelection(BuildContext context, WidgetRef ref) {
    NavigationService.navigateToGroupSelection(
      otherUserId: otherUserId,
      otherUserName: ref.read(userByIdProvider(otherUserId)).asData?.value?.displayName ?? 'User',
    );
  }

  void _showAttachmentOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Photo attachment coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Camera coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Location'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Location sharing coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }
} 