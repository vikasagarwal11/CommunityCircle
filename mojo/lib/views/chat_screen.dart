import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/chat_providers.dart';
import '../providers/auth_providers.dart';
import '../models/message_model.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/animated_reaction_button.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/swipe_to_reply_message.dart';
import '../widgets/read_receipt_widget.dart';
import '../widgets/chat_input_widget.dart';
import 'dart:async';
import '../providers/database_providers.dart';
import '../providers/user_providers.dart';
import '../providers/shared_chat_providers.dart';
import '../core/logger.dart';

// Debounce utility (modular, reusable)
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

class ChatScreen extends HookConsumerWidget {
  final String communityId;
  static final Logger _logger = Logger('ChatScreen');
  
  const ChatScreen({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(authNotifierProvider);
    final messagesAsync = ref.watch(communityMessagesProvider(communityId));
    final typingUsersAsync = ref.watch(typingUsersProvider(communityId));
    final communityAsync = ref.watch(communityProvider(communityId));
    
    // State for member selection
    final memberSearchQuery = useState('');
    final filteredMembers = useState<List<UserModel>>([]);
    final showMemberSelection = useState(false);

    // Filter members when search query changes
    useEffect(() {
      if (showMemberSelection.value) {
        final communityMembersAsync = ref.read(communityMembersProvider(communityId));
        communityMembersAsync.when(
          data: (members) {
            currentUserAsync.when(
              data: (currentUser) {
                if (currentUser == null) return;
                
                final filtered = members.where((member) {
                  // Exclude current user
                  if (member.id == currentUser.id) return false;
                  
                  // Filter by search query
                  if (memberSearchQuery.value.isNotEmpty) {
                    final query = memberSearchQuery.value.toLowerCase();
                    return (member.displayName?.toLowerCase().contains(query) ?? false) ||
                           (member.email?.toLowerCase().contains(query) ?? false);
                  }
                  return true;
                }).toList();
                
                filteredMembers.value = filtered;
              },
              loading: () => null,
              error: (_, __) => null,
            );
          },
          loading: () => null,
          error: (_, __) => null,
        );
      }
      return null;
    }, [memberSearchQuery.value, showMemberSelection.value]);

    // Show member selection modal when state changes
    useEffect(() {
      if (showMemberSelection.value) {
        _showMemberSelection(
          context, 
          ref, 
          memberSearchQuery, 
          filteredMembers,
          showMemberSelection,
        );
      }
      return null;
    }, [showMemberSelection.value]);

    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final isTyping = useState(false);
    final showEmojiPicker = useState(false);
    final replyToMessage = ref.watch(replyToMessageProvider);
    final selectedMessage = ref.watch(selectedMessageProvider);

    // Debouncer for typing indicator
    final debouncer = useMemoized(() => Debouncer(milliseconds: 500));
    useEffect(() => debouncer.dispose, []);

    // Auto-scroll to bottom when new messages arrive
    useEffect(() {
      if (messagesAsync.hasValue && messagesAsync.value!.isNotEmpty) {
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
    }, [messagesAsync]);

    // Auto-scroll to bottom when new messages arrive (only on initial load or new message sent)
    useEffect(() {
      if (messagesAsync.hasValue && messagesAsync.value!.isNotEmpty) {
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
    }, [messagesAsync]);

    // Auto-mark messages as read when viewed
    useEffect(() {
      final messages = messagesAsync.value;
      final currentUser = currentUserAsync.value;
      
      if (messages != null && currentUser != null && messages.isNotEmpty) {
        // Mark visible messages as read
        final unreadMessages = messages.where((message) => 
          message.userId != currentUser.id && 
          !message.isReadBy(currentUser.id)
        ).toList();
        
        if (unreadMessages.isNotEmpty) {
          // Mark messages as read with a slight delay to avoid spam
          Future.delayed(const Duration(milliseconds: 500), () {
            for (final message in unreadMessages) {
              ref.read(chatNotifierProvider.notifier).markAsRead(message.id);
            }
          });
        }
      }
      return null;
    }, [messagesAsync, currentUserAsync]);

    // Handle typing indicator (auto-clear after 3 seconds)
    useEffect(() {
      if (isTyping.value) {
        ref.read(chatNotifierProvider.notifier).setTypingIndicator(
          communityId: communityId,
          isTyping: true,
        );
        final timer = Timer(const Duration(seconds: 3), () {
          isTyping.value = false;
          ref.read(chatNotifierProvider.notifier).setTypingIndicator(
            communityId: communityId,
            isTyping: false,
          );
        });
        return timer.cancel;
      }
      return null;
    }, [isTyping.value]);

    return Scaffold(
      appBar: AppBar(
        title: communityAsync.when(
          data: (community) => Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Text(
                  community?.name.substring(0, 1).toUpperCase() ?? 'C',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community?.name ?? 'Community',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${community?.memberCount ?? 0} members',
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
          error: (_, __) => const Text('Community'),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              showMemberSelection.value = true;
            },
            tooltip: 'Message Member',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement message search
              NavigationService.showSnackBar(message: 'Search coming soon!');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions(context, ref);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwnMessage = currentUserAsync.value?.id == message.userId;
                    
                    return _buildMessageWithReactions(
                      context,
                      ref,
                      message,
                      isOwnMessage,
                      communityAsync,
                      ref.read(communityMembersProvider(communityId)),
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => CustomErrorWidget(
                message: 'Error loading messages: $error',
              ),
            ),
          ),

          // Typing indicator
          if (typingUsersAsync.value?.isNotEmpty == true)
            _buildTypingIndicator(context, ref, typingUsersAsync.value!),

          // Message input
          _buildMessageInput(context, ref, messageController),
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
    MessageModel message,
    bool isOwnMessage,
    WidgetRef ref,
    AsyncValue<CommunityModel?> communityAsync,
    AsyncValue<List<UserModel>> communityMembersAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(
                message.userId.substring(0, 1).toUpperCase() ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage) ...[
                  // Show sender's display name
                  ref.watch(userByIdProvider(message.userId)).when(
                    data: (user) => Text(
                      user?.displayName ?? message.userId,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    loading: () => const Text('...', style: TextStyle(fontSize: 12)),
                    error: (_, __) => Text(
                      message.userId,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                  decoration: BoxDecoration(
                    color: isOwnMessage 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: !isOwnMessage ? Border.all(
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reply preview
                      if (message.threadId != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Replying to message...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Message text
                      Text(
                        message.text ?? '',
                        style: TextStyle(
                          color: isOwnMessage ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      
                      // Media content
                      if (message.hasMedia) ...[
                        const SizedBox(height: AppConstants.smallPadding),
                        Container(
                          width: 200,
                          height: 150,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              _getMediaIcon(message.mediaType),
                              size: 40,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                      
                      // Reactions
                      if (message.hasReactions) ...[
                        const SizedBox(height: AppConstants.smallPadding),
                        Wrap(
                          spacing: 4,
                          children: message.reactions.entries.map((entry) {
                            final emoji = entry.key;
                            final count = entry.value.length;
                            final userAsync = ref.read(authNotifierProvider);
                            final isSelected = userAsync.when(
                              data: (user) => user != null && entry.value.contains(user.id),
                              loading: () => false,
                              error: (_, __) => false,
                            );
                            
                            return AnimatedReactionButton(
                              emoji: emoji,
                              count: count,
                              isSelected: isSelected,
                              onTap: () {
                                _handleReactionTap(context, ref, message, emoji);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Message info and read receipts
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    if (message.metadata?['edited'] == true) ...[
                      const SizedBox(width: 4),
                      Text(
                        'edited',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                    
                    // Read receipts (only for communities with <50 members)
                    if (communityAsync.hasValue && 
                        communityAsync.value!.memberCount < 50 &&
                        isOwnMessage) ...[
                      const SizedBox(width: 8),
                      communityMembersAsync.when(
                        data: (members) => ReadReceiptWidget(
                          message: message,
                          communityMembers: members,
                          showDetailedReceipts: communityAsync.value!.memberCount < 20,
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          if (isOwnMessage) ...[
            const SizedBox(width: AppConstants.smallPadding),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, MessageModel replyTo, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    // Show sender's display name in reply preview
                    ref.watch(userByIdProvider(replyTo.userId)).when(
                      data: (user) => Text(
                        'Replying to ${user?.displayName ?? replyTo.userId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      loading: () => const Text('Replying...', style: TextStyle(fontSize: 12)),
                      error: (_, __) => Text(
                        'Replying to ${replyTo.userId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          replyTo.userId.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Message content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              replyTo.userId,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              replyTo.text ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              ref.read(replyToMessageProvider.notifier).state = null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<bool> isTyping,
    ValueNotifier<bool> showEmojiPicker,
    WidgetRef ref,
    Debouncer debouncer,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              _showAttachmentOptions(context, ref);
            },
          ),
          
          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  debouncer.run(() {
                    isTyping.value = true;
                  });
                } else {
                  isTyping.value = false;
                }
              },
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.onSurface.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          
          // Emoji button
          IconButton(
            icon: Icon(showEmojiPicker.value ? Icons.keyboard : Icons.emoji_emotions),
            onPressed: () {
              showEmojiPicker.value = !showEmojiPicker.value;
            },
          ),
          
          // Send button
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: controller.text.trim().isEmpty ? null : () {
              _sendMessage(context, controller, ref);
            },
            style: IconButton.styleFrom(
              backgroundColor: controller.text.trim().isEmpty 
                  ? colorScheme.onSurface.withOpacity(0.1)
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: controller.text.trim().isEmpty 
                  ? colorScheme.onSurface.withOpacity(0.5)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, TextEditingController controller, WidgetRef ref) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final replyTo = ref.read(replyToMessageProvider);
    
    try {
      await ref.read(chatNotifierProvider.notifier).sendMessage(
        communityId: communityId,
        text: text,
        threadId: replyTo?.id,
      );
      
      controller.clear();
      ref.read(replyToMessageProvider.notifier).state = null;
    } catch (e) {
      NavigationService.showSnackBar(
        message: 'Failed to send message: $e',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  void _showChatOptions(BuildContext context, WidgetRef ref) {
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
            // Other options
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Messages'),
              onTap: () {
                NavigationService.goBack();
                // TODO: Implement search
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Message Member'),
              subtitle: const Text('Start 1:1 conversation'),
              onTap: () {
                NavigationService.goBack();
                _showMemberSelectionModal(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Community Info'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.navigateToCommunityDetails(communityId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat Settings'),
              onTap: () {
                NavigationService.goBack();
                // TODO: Implement chat settings
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

      // Get community members for the call
      final communityMembersAsync = ref.read(communityMembersProvider(communityId));
      communityMembersAsync.when(
        data: (members) async {
          if (members.isNotEmpty) {
            // Start the call with all community members
            final participants = members.map((member) => member.id).toList();
            
            // Use the shared chat service
            final sharedChatService = ref.read(sharedChatServiceProvider);
            await sharedChatService.startCall(
              chatId: communityId,
              callType: callType,
              participants: participants,
              chatType: 'community',
            );
            
            // Navigate to call screen
            NavigationService.navigateToCall(
              callId: '${communityId}_${DateTime.now().millisecondsSinceEpoch}',
              chatId: communityId,
              callType: callType,
            );
          } else {
            NavigationService.showSnackBar(message: 'No members available for call.');
          }
        },
        loading: () => NavigationService.showSnackBar(message: 'Loading members...'),
        error: (_, __) => NavigationService.showSnackBar(message: 'Error loading members'),
      );
    } catch (e) {
      _logger.e('Error starting call: $e');
      NavigationService.showSnackBar(
        message: 'Failed to start call: ${e.toString()}',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  void _showMemberSelection(
    BuildContext context, 
    WidgetRef ref, 
    ValueNotifier<String> searchQuery, 
    ValueNotifier<List<UserModel>> filteredMembers,
    ValueNotifier<bool> showMemberSelection,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                    showMemberSelection.value = false;
                  },
                ),
                Expanded(
                  child: Text(
                    'Message Member',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Search bar
            TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => searchQuery.value = '',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Members list
            Expanded(
              child: ref.read(communityMembersProvider(communityId)).when(
                data: (members) {
                  if (filteredMembers.value.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          Text(
                            searchQuery.value.isNotEmpty 
                                ? 'No members found'
                                : 'No members available',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (searchQuery.value.isNotEmpty) ...[
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              'Try a different search term',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredMembers.value.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers.value[index];
                      return _buildMemberTile(context, ref, member);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Text(
                        'Failed to load members',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberSelectionModal(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final filteredMembers = useState<List<UserModel>>([]);
    
    // Filter members when search query changes
    useEffect(() {
      final communityMembersAsync = ref.read(communityMembersProvider(communityId));
      communityMembersAsync.when(
        data: (members) {
          if (searchQuery.value.isNotEmpty) {
            final query = searchQuery.value.toLowerCase();
            filteredMembers.value = members.where((member) {
              return (member.displayName?.toLowerCase().contains(query) ?? false) ||
                     (member.email?.toLowerCase().contains(query) ?? false);
            }).toList();
          } else {
            filteredMembers.value = members;
          }
        },
        loading: () => filteredMembers.value = [],
        error: (_, __) => filteredMembers.value = [],
      );
    }, [searchQuery.value]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Message Member',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Search bar
            TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => searchQuery.value = '',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Members list
            Expanded(
              child: ref.read(communityMembersProvider(communityId)).when(
                data: (members) {
                  if (filteredMembers.value.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          Text(
                            searchQuery.value.isNotEmpty 
                                ? 'No members found'
                                : 'No members available',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (searchQuery.value.isNotEmpty) ...[
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              'Try a different search term',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredMembers.value.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers.value[index];
                      return _buildMemberTile(context, ref, member);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Text(
                        'Failed to load members',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, WidgetRef ref, UserModel member) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Text(
          member.displayName?.substring(0, 1).toUpperCase() ?? 'U',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        member.displayName ?? 'Unknown User',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        member.email ?? '',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.chat_bubble_outline),
        onPressed: () {
          Navigator.pop(context);
          _startPersonalChat(context, ref, member);
        },
      ),
      onTap: () {
        Navigator.pop(context);
        _startPersonalChat(context, ref, member);
      },
    );
  }

  void _startPersonalChat(BuildContext context, WidgetRef ref, UserModel member) {
    // Navigate to personal chat with the selected member
    NavigationService.navigateToPersonalChat(member.id);
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
                Navigator.pop(context);
                // TODO: Implement photo picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement video picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Audio'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement audio recorder
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement document picker
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMediaIcon(String? mediaType) {
    switch (mediaType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.insert_drive_file;
      default:
        return Icons.attach_file;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  // Handle reaction tap
  void _handleReactionTap(BuildContext context, WidgetRef ref, MessageModel message, String emoji) {
    final userAsync = ref.read(authNotifierProvider);
    userAsync.when(
      data: (user) {
        if (user == null) return;
        
        final chatNotifier = ref.read(chatNotifierProvider.notifier);
        final hasReaction = message.reactions[emoji]?.contains(user.id) ?? false;
        
        if (hasReaction) {
          // Remove reaction
          chatNotifier.removeReaction(
            messageId: message.id,
            emoji: emoji,
          );
        } else {
          // Add reaction
          chatNotifier.addReaction(
            messageId: message.id,
            emoji: emoji,
          );
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  // Show reaction picker
  void _showReactionPicker(BuildContext context, WidgetRef ref, MessageModel message) {
    final userAsync = ref.read(authNotifierProvider);
    userAsync.when(
      data: (user) {
        if (user == null) return;
        
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: ReactionPicker(
              onReactionSelected: (emoji) {
                final chatNotifier = ref.read(chatNotifierProvider.notifier);
                chatNotifier.addReaction(
                  messageId: message.id,
                  emoji: emoji,
                );
              },
              onClose: () {
                Navigator.of(context).pop();
              },
              selectedReaction: null, // TODO: Get user's current reaction
            ),
          ),
        );
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  // Add long press gesture to message for reaction picker and swipe-to-reply
  Widget _buildMessageWithReactions(
    BuildContext context,
    WidgetRef ref,
    MessageModel message,
    bool isOwnMessage,
    AsyncValue<CommunityModel?> communityAsync,
    AsyncValue<List<UserModel>> communityMembersAsync,
  ) {
    return SwipeToReplyMessage(
      message: message,
      isOwnMessage: isOwnMessage,
      onReply: () {
        // Focus on the text input when reply is triggered
        // This will be handled by the reply preview widget
      },
      child: GestureDetector(
        onLongPress: () {
          _showReactionPicker(context, ref, message);
        },
        child: _buildMessageTile(context, message, isOwnMessage, ref, communityAsync, communityMembersAsync),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context, WidgetRef ref, List<String> typingUsers) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            '${typingUsers.length} ${typingUsers.length == 1 ? 'person' : 'people'} typing...',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, WidgetRef ref, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              // TODO: Implement send message
            },
          ),
        ],
      ),
    );
  }
} 