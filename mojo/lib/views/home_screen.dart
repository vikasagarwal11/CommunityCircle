import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';
import '../models/community_model.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'notification_test_widget.dart';

// User role provider for role-based UI
final userRoleProvider = FutureProvider<String>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserRole();
});

// Search box widget with inherited widget for search query state
class _MyCommunitiesSearchBox extends StatefulWidget {
  const _MyCommunitiesSearchBox({Key? key}) : super(key: key);

  static _MyCommunitiesSearchBoxState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyCommunitiesSearchBoxState>();
  }

  @override
  State<_MyCommunitiesSearchBox> createState() => _MyCommunitiesSearchBoxState();
}

class _MyCommunitiesSearchBoxState extends State<_MyCommunitiesSearchBox> {
  String searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search communities...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final userRoleAsync = ref.watch(userRoleProvider);
    final publicCommunitiesAsync = ref.watch(publicCommunitiesProvider(const CommunityQueryParams(limit: 5)));
    final userCommunitiesAsync = ref.watch(userCommunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              NavigationService.navigateToSearch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              NavigationService.navigateToProfile();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text('No user data available'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Card
                  _buildUserCard(context, user),
                  const SizedBox(height: AppConstants.defaultPadding),
                  // Challenge Hub Section
                  _buildChallengeHub(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  // Public Communities Section
                  _buildPublicCommunities(context, ref, publicCommunitiesAsync),
                  const SizedBox(height: AppConstants.defaultPadding),
                  // My Communities Section (hidden for anonymous users)
                  userRoleAsync.when(
                    data: (role) => role != 'anonymous' 
                        ? _buildMyCommunities(context, userCommunitiesAsync)
                        : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  // Notification Test Widget (temporary for testing)
                  const NotificationTestWidget(),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: null, // Use default icon color
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Error loading user data',
                  style: Theme.of(context).textTheme.headlineSmall,
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
      floatingActionButton: ref.watch(canCreateCommunityProvider).when(
        data: (canCreate) => canCreate
            ? FloatingActionButton(
                onPressed: () {
                  NavigationService.navigateToCreateCommunity();
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        loading: () => const SizedBox(),
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: user.role == 'anonymous' 
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.primary,
              child: Text(
                user.displayName?.substring(0, 1).toUpperCase() ?? 
                (user.role == 'anonymous' ? 'G' : user.phoneNumber.substring(0, 1)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? (user.role == 'anonymous' ? 'Guest' : 'User'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    user.role == 'anonymous' 
                        ? 'Guest User' 
                        : user.phoneNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user.role == 'anonymous' 
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role == 'anonymous' 
                          ? 'GUEST' 
                          : '${user.totalPoints} Points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (user.role == 'anonymous')
              IconButton(
                icon: const Icon(Icons.login),
                onPressed: () {
                  NavigationService.navigateToPhoneAuth();
                },
                tooltip: 'Sign up for full access',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeHub(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Challenge Hub',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                const Text(
                  'Challenge Hub',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Complete challenges to earn points!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Sign up to participate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYourCommunities(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(userCommunitiesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Communities',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        communitiesAsync.when(
          data: (communities) {
            if (communities.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('Join a community to see it here!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ref.watch(canCreateCommunityProvider).when(
                      data: (canCreate) => canCreate
                          ? ElevatedButton(
                              onPressed: () => NavigationService.navigateToCreateCommunity(),
                              child: const Text('Create Community'),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Sign In Required'),
                                    content: const Text(
                                      'You need to sign in with your phone number to create communities.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          NavigationService.navigateToPhoneAuth();
                                        },
                                        child: const Text('Sign In'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Sign In to Create'),
                            ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: AppConstants.mediumAnimation,
                  child: Card(
                    elevation: AppConstants.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: community.coverImage.isNotEmpty
                            ? NetworkImage(community.coverImage)
                            : null,
                        child: community.coverImage.isEmpty
                            ? Text(community.name.substring(0, 1))
                            : null,
                      ),
                      title: Text(community.name),
                      subtitle: Text('${community.memberCount} Members'),
                      onTap: () {
                        NavigationService.navigateToCommunityDetails(community.id, community: community);
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(message: 'Loading your communities...'),
          error: (error, _) => CustomErrorWidget(
            message: 'Error loading your communities',
            error: error.toString(),
            onRetry: () => ref.refresh(userCommunitiesProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicCommunities(BuildContext context, WidgetRef ref, AsyncValue<List<CommunityModel>> publicCommunitiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Communities',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        publicCommunitiesAsync.when(
          data: (communities) {
            if (communities.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.public, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text('No public communities found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => NavigationService.navigateToCreateCommunity(),
                      child: const Text('Create Community'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: AppConstants.mediumAnimation,
                  child: Card(
                    elevation: AppConstants.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: community.coverImage.isNotEmpty
                            ? NetworkImage(community.coverImage)
                            : null,
                        child: community.coverImage.isEmpty
                            ? Text(community.name.substring(0, 1))
                            : null,
                      ),
                      title: Text(community.name),
                      subtitle: Text('${community.memberCount} Members'),
                      onTap: () {
                        NavigationService.navigateToCommunityDetails(community.id, community: community);
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingWidget(message: 'Loading public communities...'),
          error: (error, _) => CustomErrorWidget(
            message: 'Error loading public communities',
            error: error.toString(),
            onRetry: () => ref.invalidate(publicCommunitiesProvider(const CommunityQueryParams(limit: 5))),
          ),
        ),
      ],
    );
  }

  Widget _buildMyCommunities(BuildContext context, AsyncValue<List<CommunityModel>> communitiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Communities',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        // Search box
        _MyCommunitiesSearchBox(),
        const SizedBox(height: AppConstants.smallPadding),
        SizedBox(
          height: 4 * 60.0 + 16, // 4 items + padding
          child: communitiesAsync.when(
            data: (communities) {
              return Consumer(
                builder: (context, ref, child) {
                  final searchQuery = _MyCommunitiesSearchBox.of(context)?.searchQuery ?? '';
                  final filtered = searchQuery.isEmpty
                      ? communities
                      : communities.where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                  final showSeeAll = filtered.length > 4;
                  final visible = filtered.take(4).toList();
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final community = visible[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              NavigationService.navigateToCommunityDetails(community.id);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(AppConstants.defaultPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    community.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    community.description,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${community.memberCount} members',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (showSeeAll)
                    TextButton(
                      onPressed: () {
                        _showAllCommunitiesModal(context, filtered);
                      },
                      child: const Text('See All'),
                    ),
                ],
              );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading communities: $error')),
          ),
        ),
      ],
    );
  }

void _showAllCommunitiesModal(BuildContext context, List<CommunityModel> communities) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      String search = '';
      return StatefulBuilder(
        builder: (context, setState) {
          final filtered = search.isEmpty
              ? communities
              : communities.where((c) => c.name.toLowerCase().contains(search.toLowerCase())).toList();
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search all communities...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          search = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final community = filtered[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              NavigationService.navigateToCommunityDetails(community.id);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(AppConstants.defaultPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    community.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    community.description,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${community.memberCount} members',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildEmptyPublicCommunities(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.group_add,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'No public communities yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to create a community!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          ElevatedButton.icon(
            onPressed: () {
              NavigationService.navigateToCreateCommunity();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Community'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
} 