import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/chat_providers.dart';
import '../providers/auth_providers.dart';
import '../models/message_model.dart';
import '../core/constants.dart';

import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/animated_reaction_button.dart';
import '../widgets/reaction_picker.dart';
import 'dart:async';
import '../providers/database_providers.dart';

class ChatScreen extends HookConsumerWidget {
  final String communityId;
  
  const ChatScreen({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider(communityId));
    final communityAsync = ref.watch(communityProvider(communityId));
    final typingUsersAsync = ref.watch(typingUsersProvider(communityId));
    final userAsync = ref.watch(authNotifierProvider);
    final chatNotifier = ref.watch(chatNotifierProvider.notifier);
    
    final messageController = useTextEditingController();
    final scrollController = useScrollController();
    final isTyping = useState(false);
    final showEmojiPicker = useState(false);
    final replyToMessage = ref.watch(replyToMessageProvider);
    final selectedMessage = ref.watch(selectedMessageProvider);

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

    // Handle typing indicator
    useEffect(() {
      if (isTyping.value) {
        chatNotifier.setTypingIndicator(
          communityId: communityId,
          isTyping: true,
        );
        
        final timer = Timer(const Duration(seconds: 3), () {
          isTyping.value = false;
          chatNotifier.setTypingIndicator(
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
          // Reply preview
          if (replyToMessage != null) _buildReplyPreview(context, replyToMessage, ref),
          
          // Messages list
          Expanded(
            child: messagesAsync.when(
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
                    final isOwnMessage = userAsync.value?.id == message.userId;
                    
                    return _buildMessageWithReactions(
                      context,
                      message,
                      isOwnMessage,
                      ref,
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) {
                final errorMsg = error.toString();
                if (errorMsg.contains('permission-denied')) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Icon(Icons.lock, color: colorScheme.error, size: 48),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.error.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'You do not have permission to view messages in this community.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Please ensure you have joined and been approved.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.error.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return CustomErrorWidget(
                  message: 'Error loading messages: $error',
                );
              },
            ),
          ),
          
          // Typing indicator
          typingUsersAsync.when(
            data: (typingUsers) {
              if (typingUsers.isEmpty) return const SizedBox();
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
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          
          // Only show input if not permission denied
          if (!(messagesAsync.hasError && messagesAsync.error.toString().contains('permission-denied')))
            _buildChatInput(
              context,
              messageController,
              isTyping,
              showEmojiPicker,
              ref,
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
    MessageModel message,
    bool isOwnMessage,
    WidgetRef ref,
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
                  Text(
                    message.userId ?? '', // TODO: Get user display name
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withOpacity(0.7),
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
                          ),
                          child: Text(
                            'Replying to message...',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
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
                            final userAsync = ref.watch(authNotifierProvider);
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
                
                // Message info
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
                Text(
                  'Replying to ${replyTo.userId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.text ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                isTyping.value = value.isNotEmpty;
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
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Messages'),
              onTap: () {
                NavigationService.goBack();
                // TODO: Implement search
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

  // Add long press gesture to message for reaction picker
  Widget _buildMessageWithReactions(
    BuildContext context,
    MessageModel message,
    bool isOwnMessage,
    WidgetRef ref,
  ) {
    return GestureDetector(
      onLongPress: () {
        _showReactionPicker(context, ref, message);
      },
      child: _buildMessageTile(context, message, isOwnMessage, ref),
    );
  }
} 