import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/chat_providers.dart';
import '../providers/auth_providers.dart';
import '../models/message_model.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
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
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Text(
                  community?.name.substring(0, 1).toUpperCase() ?? 'C',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
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
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
        backgroundColor: AppTheme.neutralWhite,
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
                    
                    return _buildMessageTile(
                      context,
                      message,
                      isOwnMessage,
                      ref,
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => CustomErrorWidget(
                message: 'Error loading messages: $error',
              ),
            ),
          ),
          
          // Typing indicator
          typingUsersAsync.when(
            data: (typingUsers) {
              if (typingUsers.isEmpty) return const SizedBox();
              
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
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          
          // Chat input
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.onSurfaceColor,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Start the conversation by sending a message!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: Text(
                message.userId.substring(0, 1).toUpperCase() ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryBlue,
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
                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
                        ? AppTheme.primaryBlue 
                        : AppTheme.neutralWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: !isOwnMessage ? Border.all(
                      color: AppTheme.onSurfaceColor.withOpacity(0.1),
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
                            color: AppTheme.onSurfaceColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Replying to message...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                      
                      // Message text
                      Text(
                        message.text ?? '',
                        style: TextStyle(
                          color: isOwnMessage ? Colors.white : AppTheme.onSurfaceColor,
                        ),
                      ),
                      
                      // Media content
                      if (message.hasMedia) ...[
                        const SizedBox(height: AppConstants.smallPadding),
                        Container(
                          width: 200,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppTheme.onSurfaceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              _getMediaIcon(message.mediaType),
                              size: 40,
                              color: AppTheme.onSurfaceColor.withOpacity(0.5),
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
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.onSurfaceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(entry.key),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${entry.value.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
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
                        color: AppTheme.onSurfaceColor.withOpacity(0.5),
                      ),
                    ),
                    if (message.metadata?['edited'] == true) ...[
                      const SizedBox(width: 4),
                      Text(
                        'edited',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.onSurfaceColor.withOpacity(0.5),
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
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryGreen,
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
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.onSurfaceColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.onSurfaceColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
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
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.text ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.neutralWhite,
        border: Border(
          top: BorderSide(
            color: AppTheme.onSurfaceColor.withOpacity(0.1),
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
                fillColor: AppTheme.onSurfaceColor.withOpacity(0.05),
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
              _sendMessage(controller, ref);
            },
            style: IconButton.styleFrom(
              backgroundColor: controller.text.trim().isEmpty 
                  ? AppTheme.onSurfaceColor.withOpacity(0.1)
                  : AppTheme.primaryBlue,
              foregroundColor: controller.text.trim().isEmpty 
                  ? AppTheme.onSurfaceColor.withOpacity(0.5)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(TextEditingController controller, WidgetRef ref) async {
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
        backgroundColor: AppTheme.errorColor,
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
                Navigator.pop(context);
                // TODO: Implement search
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Community Info'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToCommunityDetails(communityId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat Settings'),
              onTap: () {
                Navigator.pop(context);
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
} 