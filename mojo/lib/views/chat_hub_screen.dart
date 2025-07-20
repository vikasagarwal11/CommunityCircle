import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../providers/chat_providers.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/personal_message_model.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../views/user_search_screen.dart';

class ChatHubScreen extends HookConsumerWidget {
  const ChatHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final userCommunitiesAsync = ref.watch(userCommunitiesProvider);
    final searchQuery = useState('');
    final filteredCommunities = useState<List<CommunityModel>>([]);

    // Filter communities based on search
    useEffect(() {
      userCommunitiesAsync.when(
        data: (communities) {
          if (searchQuery.value.isEmpty) {
            filteredCommunities.value = communities;
          } else {
            filteredCommunities.value = communities.where((community) {
              final query = searchQuery.value.toLowerCase();
              return community.name.toLowerCase().contains(query) ||
                     community.description.toLowerCase().contains(query) ||
                     community.tags.any((tag) => tag.toLowerCase().contains(query));
            }).toList();
          }
        },
        loading: () => filteredCommunities.value = [],
        error: (_, __) => filteredCommunities.value = [],
      );
      return null;
    }, [searchQuery.value, userCommunitiesAsync]);



    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chats'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Focus search field
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatHubOptions(context, ref);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(context, searchQuery),
          
          // Community chats list
          Expanded(
            child: _buildCommunitiesTab(context, ref, userAsync, filteredCommunities),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ValueNotifier<String> searchQuery) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: TextField(
        onChanged: (value) => searchQuery.value = value,
        decoration: InputDecoration(
          hintText: 'Search communities...',
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
        ),
      ),
    );
  }

  Widget _buildCommunitiesTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserModel?> userAsync,
    ValueNotifier<List<CommunityModel>> filteredCommunities,
  ) {
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(
            child: Text('Please log in to view your chats'),
          );
        }

        if (filteredCommunities.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'No communities found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Join communities to start chatting',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppConstants.largePadding),
                ElevatedButton.icon(
                  onPressed: () {
                    NavigationService.navigateToSearch();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Discover Communities'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredCommunities.value.length,
          itemBuilder: (context, index) {
            final community = filteredCommunities.value[index];
            return _buildCommunityChatTile(context, ref, community);
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load user data',
        error: error.toString(),
      ),
    );
  }





  Widget _buildCommunityChatTile(BuildContext context, WidgetRef ref, CommunityModel community) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            community.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          community.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              community.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${community.members.length} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                                 Text(
                   _formatTime(community.createdAt),
                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                     color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                   ),
                 ),
              ],
            ),
          ],
        ),
                 trailing: null, // TODO: Add unread count when implemented
        onTap: () {
          NavigationService.navigateToChat(community.id);
        },
        onLongPress: () {
          _showCommunityOptions(context, ref, community);
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'No Communities Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Join communities to start chatting!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.largePadding),
          ElevatedButton.icon(
            onPressed: () {
              NavigationService.navigateToSearch();
            },
            icon: const Icon(Icons.search),
            label: const Text('Discover Communities'),
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

  Widget _buildNoResultsState(BuildContext context, String query) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showChatHubOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Communities'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.navigateToSearch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create Community'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.navigateToCreateCommunity();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat Settings'),
              onTap: () {
                NavigationService.goBack();
                _showChatHubSettings(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatHubSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Global Notifications'),
              subtitle: const Text('Receive notifications for all chats'),
              value: true, // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update global notification settings
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
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Preferences'),
              subtitle: const Text('Customize notification settings'),
              onTap: () {
                // TODO: Navigate to notification preferences
                Navigator.pop(context);
                NavigationService.showSnackBar(
                  message: 'Notification preferences coming soon!',
                  backgroundColor: Colors.orange,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              subtitle: const Text('Manage chat privacy'),
              onTap: () {
                // TODO: Navigate to privacy settings
                Navigator.pop(context);
                NavigationService.showSnackBar(
                  message: 'Privacy settings coming soon!',
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

  void _showCommunityOptions(BuildContext context, WidgetRef ref, CommunityModel community) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Community Info'),
              onTap: () {
                NavigationService.goBack();
                NavigationService.navigateToCommunityDetails(community.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              onTap: () {
                NavigationService.goBack();
                // TODO: Implement notification settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive Chat'),
              onTap: () {
                NavigationService.goBack();
                // TODO: Implement archive functionality
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
}

 