import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../models/personal_message_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../views/user_search_screen.dart';

class PersonalChatHubScreen extends HookConsumerWidget {
  const PersonalChatHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final personalChatsAsync = ref.watch(personalChatsProvider);
    final searchQuery = useState('');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Chats'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              NavigationService.showSnackBar(message: 'Search coming soon!');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showPersonalChatHubOptions(context, ref);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(context, searchQuery),
          
          // Personal chats list
          Expanded(
            child: userAsync.when(
              data: (user) {
                if (user == null) {
                  return const Center(
                    child: Text('Please log in to view personal messages'),
                  );
                }

                return personalChatsAsync.when(
                  data: (personalChats) {
                    if (personalChats.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      itemCount: personalChats.length,
                      itemBuilder: (context, index) {
                        final chat = personalChats[index];
                        return _buildPersonalChatTile(context, ref, chat, user);
                      },
                    );
                  },
                  loading: () => const LoadingWidget(),
                  error: (error, stack) => CustomErrorWidget(
                    message: 'Failed to load personal chats',
                    error: error.toString(),
                  ),
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, stack) => CustomErrorWidget(
                message: 'Failed to load user data',
                error: error.toString(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'personal_chat_fab',
        onPressed: () => _showCreateChatOptions(context),
        child: const Icon(Icons.person_add),
        tooltip: 'New Chat',
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ValueNotifier<String> searchQuery) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: TextField(
        onChanged: (value) => searchQuery.value = value,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildPersonalChatTile(BuildContext context, WidgetRef ref, PersonalChatModel chat, UserModel currentUser) {
    // Determine the other user's ID and data
    final otherUserId = chat.user1Id == currentUser.id ? chat.user2Id : chat.user1Id;
    final otherUserData = chat.user1Id == currentUser.id ? chat.user2Data : chat.user1Data;
    
    // Get other user's display name
    final otherUserName = otherUserData['displayName'] ?? otherUserData['email'] ?? 'Unknown User';
    final otherUserEmail = otherUserData['email'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: otherUserData['profilePictureUrl'] != null 
              ? NetworkImage(otherUserData['profilePictureUrl'])
              : null,
          child: otherUserData['profilePictureUrl'] == null
              ? Text(
                  otherUserName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          otherUserName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.lastMessage != null) ...[
              Text(
                chat.lastMessage!.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Text(
                  _formatTime(chat.lastMessageTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (chat.unreadCount > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${chat.unreadCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          NavigationService.navigateToPersonalChat(otherUserId);
        },
        onLongPress: () {
          _showPersonalChatOptions(context, ref, chat, otherUserId);
        },
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
              Icons.person_outline,
              size: 60,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'No personal messages yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Start 1:1 conversations with other users',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.largePadding),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Find People'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding,
                vertical: AppConstants.defaultPadding,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPersonalChatHubOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Conversations'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Search coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat Settings'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Settings coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archived Chats'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Archived chats coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalChatOptions(BuildContext context, WidgetRef ref, PersonalChatModel chat, String otherUserId) {
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
                NavigationService.showSnackBar(message: 'Search coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Profile view coming soon!');
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
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Chat'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.showSnackBar(message: 'Delete chat coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    
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

  void _showCreateChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Start New Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserSearchScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create Group Chat'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.showSnackBar(message: 'Group chats coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.contacts),
              title: const Text('Import Contacts'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.showSnackBar(message: 'Contact import coming soon!');
              },
            ),
          ],
        ),
      ),
    );
  }
} 