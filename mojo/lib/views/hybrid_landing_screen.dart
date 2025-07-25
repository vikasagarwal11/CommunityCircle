import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/community_providers.dart';
import '../providers/user_providers.dart';
import '../providers/auth_providers.dart';
import '../core/navigation_service.dart';
import '../core/theme.dart';
import '../core/logger.dart';
import '../core/constants.dart';
import '../routes/app_routes.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../widgets/welcome_flash_screen.dart';
import '../widgets/welcome_onboarding_dialog.dart';
import 'community_details_screen.dart';
import 'create_community_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'notification_preferences_screen.dart';
import 'admin_management_screen.dart';
import 'rsvp_management_screen.dart';
import 'feed_landing_screen.dart';

// View mode provider
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.list);

// Search query providers
final myCommunitiesSearchQueryProvider = StateProvider<String>((ref) => '');
final exploreCommunitiesSearchQueryProvider = StateProvider<String>((ref) => '');

enum ViewMode { list, feed }

class HybridLandingScreen extends HookConsumerWidget {
  const HybridLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    final userAsync = ref.watch(authNotifierProvider);
    // Comment out undefined provider
    // final userRoleAsync = ref.watch(userRoleProvider);
    final publicCommunitiesAsync = ref.watch(publicCommunitiesProvider(const CommunityQueryParams(limit: 20)));
    final userCommunitiesAsync = ref.watch(userCommunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          // View mode toggle
          IconButton(
            icon: Icon(viewMode == ViewMode.list ? Icons.view_stream : Icons.view_list),
            onPressed: () {
              ref.read(viewModeProvider.notifier).state = 
                  viewMode == ViewMode.list ? ViewMode.feed : ViewMode.list;
            },
            tooltip: viewMode == ViewMode.list ? 'Switch to Feed View' : 'Switch to List View',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              NavigationService.navigateToSearch();
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

            // Show feed view or list view based on mode
            if (viewMode == ViewMode.feed) {
              return const FeedLandingScreen();
            }

            // List view (current implementation)
            return ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                // My Communities (top) - Always show for now
                _buildMyCommunities(context, userCommunitiesAsync, ref),
                const SizedBox(height: AppConstants.largePadding),
                // Explore Communities (bottom)
                _ExploreCommunitiesSection(
                  publicCommunitiesAsync: publicCommunitiesAsync,
                  maxToShow: 6,
                ),
              ],
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
                  color: Colors.red,
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
                heroTag: 'hybrid_landing_fab',
                onPressed: () => NavigationService.navigateToCreateCommunity(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                tooltip: 'Create Community',
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        loading: () => const SizedBox(),
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildMyCommunities(BuildContext context, AsyncValue<List<CommunityModel>> communitiesAsync, WidgetRef ref) {
    final searchQuery = ref.watch(myCommunitiesSearchQueryProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search icon
        Row(
          children: [
            Expanded(
              child: Text(
                'My Communities',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                searchQuery.isEmpty ? Icons.search_outlined : Icons.search,
                color: searchQuery.isEmpty 
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _showInlineSearch(context, ref, 'my'),
            ),
          ],
        ),
        
        // Inline search bar (appears when search is active)
        if (searchQuery.isNotEmpty) ...[
          const SizedBox(height: AppConstants.smallPadding),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search my communities...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      ref.read(myCommunitiesSearchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    ref.read(myCommunitiesSearchQueryProvider.notifier).state = '';
                  },
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: AppConstants.smallPadding),
        communitiesAsync.when(
          data: (communities) {
            if (communities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      'No communities yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      'Join or create your first community to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => NavigationService.navigateToSearch(),
                          icon: const Icon(Icons.search),
                          label: const Text('Explore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        ElevatedButton.icon(
                          onPressed: () => NavigationService.navigateToCreateCommunity(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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
                return Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                  child: InkWell(
                    onTap: () => NavigationService.navigateToCommunityDetails(community.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.smallPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              community.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${community.memberCount} members',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: AppConstants.smallPadding),
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${community.eventCount} events',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
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
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Error loading communities',
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
                const SizedBox(height: AppConstants.defaultPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => NavigationService.navigateToSearch(),
                      icon: const Icon(Icons.search),
                      label: const Text('Explore'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    ElevatedButton.icon(
                      onPressed: () => NavigationService.navigateToCreateCommunity(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showInlineSearch(BuildContext context, WidgetRef ref, String type) {
    final searchQuery = ref.read(myCommunitiesSearchQueryProvider);
    if (searchQuery.isNotEmpty) {
      ref.read(myCommunitiesSearchQueryProvider.notifier).state = '';
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchScreen(
            initialQuery: type == 'my' ? searchQuery : '',
          ),
        ),
      );
    }
  }
}

class _ExploreCommunitiesSection extends ConsumerWidget {
  final AsyncValue<List<CommunityModel>> publicCommunitiesAsync;
  final int maxToShow;

  const _ExploreCommunitiesSection({
    required this.publicCommunitiesAsync,
    required this.maxToShow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(exploreCommunitiesSearchQueryProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search icon
        Row(
          children: [
            Expanded(
              child: Text(
                'Explore Communities',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                searchQuery.isEmpty ? Icons.search_outlined : Icons.search,
                color: searchQuery.isEmpty 
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _showExploreSearch(context, ref),
            ),
          ],
        ),
        
        // Inline search bar (appears when search is active)
        if (searchQuery.isNotEmpty) ...[
          const SizedBox(height: AppConstants.smallPadding),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search communities...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      ref.read(exploreCommunitiesSearchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    ref.read(exploreCommunitiesSearchQueryProvider.notifier).state = '';
                  },
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: AppConstants.smallPadding),
        publicCommunitiesAsync.when(
          data: (communities) {
            if (communities.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      'No public communities available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      'Check back later for new communities to join',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final communitiesToShow = communities.take(maxToShow).toList();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: communitiesToShow.length,
              itemBuilder: (context, index) {
                final community = communitiesToShow[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                  child: InkWell(
                    onTap: () => NavigationService.navigateToCommunityDetails(community.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.smallPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              community.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${community.memberCount} members',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: AppConstants.smallPadding),
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${community.eventCount} events',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
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
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Error loading communities',
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
      ],
    );
  }

  void _showExploreSearch(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.read(exploreCommunitiesSearchQueryProvider);
    if (searchQuery.isNotEmpty) {
      ref.read(exploreCommunitiesSearchQueryProvider.notifier).state = '';
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchScreen(
            initialQuery: searchQuery,
          ),
        ),
      );
    }
  }
} 