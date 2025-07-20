import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/message_model.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/offline_providers.dart';
import '../providers/database_providers.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../core/theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/offline_status_widget.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/swipe_to_reply_message.dart';

class ChatScreen extends HookConsumerWidget {
  final String communityId;
  final CommunityModel? community;

  const ChatScreen({
    super.key,
    required this.communityId,
    this.community,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final messagesAsync = ref.watch(offlineFirstMessagesProvider(communityId));
    final offlineStatus = ref.watch(offlineStatusProvider);
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (community?.coverImage.isNotEmpty == true)
              CircleAvatar(
                radius: 16,
                backgroundImage: CachedNetworkImageProvider(community!.coverImage),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    community?.name ?? 'Chat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (community != null)
                    Text(
                      '${community!.members.length} members',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showMessageSearch(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatSettings(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline status widget for chat
          const OfflineStatusWidget(),
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'Be the first to start a conversation!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageTile(context, message, ref);
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) {
                // Check if it's a permission error
                if (error.toString().contains('permission-denied')) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'Access Denied',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'You don\'t have permission to view messages in this community.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        ElevatedButton(
                          onPressed: () {
                            // Try to refresh the data
                            ref.invalidate(offlineFirstMessagesProvider(communityId));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                // General error
                return Center(
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
                        'Error loading messages',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(offlineFirstMessagesProvider(communityId));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Chat input
          ChatInputWidget(
            controller: textController,
            onSendMessage: (text) => _sendMessage(context, ref, text),
            isOffline: !offlineStatus.isOnline,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(BuildContext context, MessageModel message, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    
    return userAsync.when(
      data: (currentUser) {
        final isOwnMessage = currentUser?.id == message.userId;
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          child: Row(
            mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isOwnMessage) ...[
                Consumer(
                  builder: (context, ref, child) {
                    final userAsync = ref.watch(userProvider(message.userId));
                    return userAsync.when(
                      data: (user) => CircleAvatar(
                        radius: 16,
                        backgroundImage: user?.profilePictureUrl != null
                            ? CachedNetworkImageProvider(user!.profilePictureUrl!)
                            : null,
                        child: user?.profilePictureUrl == null
                            ? Text(
                                user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      loading: () => const CircleAvatar(
                        radius: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 16),
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppConstants.smallPadding),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                  decoration: BoxDecoration(
                    color: isOwnMessage
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isOwnMessage) ...[
                        Consumer(
                          builder: (context, ref, child) {
                            final userAsync = ref.watch(userProvider(message.userId));
                            return userAsync.when(
                              data: (user) => Text(
                                user?.displayName ?? 'Unknown User',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isOwnMessage
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              loading: () => const Text(
                                'Loading...',
                                style: TextStyle(fontSize: 12),
                              ),
                              error: (_, __) => const Text(
                                'Unknown User',
                                style: TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        message.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isOwnMessage
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isOwnMessage
                                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                          if (isOwnMessage) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.readBy.isNotEmpty ? Icons.done_all : Icons.done,
                              size: 12,
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _sendMessage(BuildContext context, WidgetRef ref, String text) {
    if (text.trim().isEmpty) return;

    ref.read(offlineSyncNotifierProvider.notifier).sendMessageOffline(
      text: text.trim(),
      communityId: communityId,
    );

    // Clear the text controller
    // Note: This will be handled by the ChatInputWidget
  }

  void _showChatSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Receive message notifications'),
              value: true, // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update notification settings
              },
            ),
            SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Play sound for new messages'),
              value: true, // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update sound settings
              },
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate for new messages'),
              value: false, // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update vibration settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block Community'),
              subtitle: const Text('Stop receiving messages'),
              onTap: () {
                // TODO: Implement block functionality
                Navigator.pop(context);
                NavigationService.showSnackBar(
                  message: 'Block functionality coming soon!',
                  backgroundColor: Colors.orange,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Community'),
              subtitle: const Text('Report inappropriate content'),
              onTap: () {
                // TODO: Implement report functionality
                Navigator.pop(context);
                NavigationService.showSnackBar(
                  message: 'Report functionality coming soon!',
                  backgroundColor: Colors.orange,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Save settings
              Navigator.pop(context);
              NavigationService.showSnackBar(
                message: 'Settings saved!',
                backgroundColor: Colors.green,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMessageSearch(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search for messages...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                // TODO: Implement search functionality
                // This would filter messages based on the query
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to search results
              Navigator.pop(context);
              NavigationService.showSnackBar(
                message: 'Search functionality coming soon!',
                backgroundColor: Colors.orange,
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
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
        child: _buildMessageTile(context, message, ref),
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
              _sendMessage(context, ref, controller.text);
            },
          ),
        ],
      ),
    );
  }
} 