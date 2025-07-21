import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cached_network_image/cached_network_image.dart'; // New import for performance
import 'package:flutter_animate/flutter_animate.dart'; // New import for animations
import 'package:connectivity_plus/connectivity_plus.dart'; // New import for offline handling
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/community_providers.dart';
import '../providers/user_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/offline_providers.dart';
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
import '../widgets/offline_status_widget.dart';
import 'community_details_screen.dart';
import 'create_community_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'notification_preferences_screen.dart';
import 'admin_management_screen.dart';
import 'rsvp_management_screen.dart';

// User role provider for role-based UI
final userRoleProvider = FutureProvider<String>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserRole();
});

// Add a StateProvider for the My Communities search query
final myCommunitiesSearchQueryProvider = StateProvider<String>((ref) => '');

// Add a StateProvider for the Explore Communities search query
final exploreCommunitiesSearchQueryProvider = StateProvider<String>((ref) => '');

// New: Connectivity provider for offline detection
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// New: Sorting provider for My Communities (personalization)
final myCommunitiesSortProvider = StateProvider<String>((ref) => 'name'); // Options: 'name', 'members'

// StateProvider for selected filter (e.g., interests, trending)
final exploreFilterProvider = StateProvider<String?>((ref) => null);

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _scrollController = useScrollController();
    final userAsync = ref.watch(authNotifierProvider);
    final userRoleAsync = ref.watch(userRoleProvider);
    final paginatedCommunitiesState = ref.watch(paginatedCommunitiesProvider);
    final userCommunitiesAsync = ref.watch(userCommunitiesProvider);
    final userInterestsAsync = ref.watch(userInterestsProvider); // Added for My Communities
    final offlineStatus = ref.watch(offlineStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          // Offline indicator in app bar
          const OfflineIndicator(),
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
              ref.read(otpSentProvider.notifier).state = false;
              ref.read(authErrorProvider.notifier).state = null;
              ref.read(authLoadingProvider.notifier).state = false;
              ref.read(phoneNumberProvider.notifier).state = '';
              ref.read(verificationIdProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline banner at the top
            const OfflineBanner(),
            // Offline status widget
            const OfflineStatusWidget(),
            // Main content
            Expanded(
              child: userAsync.when(
                data: (user) {
                  if (user == null) {
                    // Navigate to phone auth screen if user is null
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      NavigationService.navigateToPhoneAuth();
                    });
                    return const SizedBox.shrink();
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(paginatedCommunitiesProvider.notifier).refresh(),
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      children: [
                        // My Communities (top)
                        userRoleAsync.when(
                          data: (role) => role != 'anonymous'
                              ? _buildMyCommunities(context, userCommunitiesAsync, ref, user, userInterestsAsync)
                              : const SizedBox(),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                        const SizedBox(height: AppConstants.largePadding),
                        // Enhanced Explore Communities with pagination
                        _buildEnhancedExploreCommunities(context, paginatedCommunitiesState, ref, user),
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
          ],
        ),
      ),

    );
  }

  Widget _buildMyCommunities(BuildContext context, AsyncValue<List<CommunityModel>> communitiesAsync, WidgetRef ref, UserModel? user, AsyncValue<Set<String>> userInterestsAsync) {
    final searchQuery = ref.watch(myCommunitiesSearchQueryProvider);
    final sort = ref.watch(myCommunitiesSortProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search icon and sorting dropdown
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
            DropdownButton<String>(
              value: sort,
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                DropdownMenuItem(value: 'members', child: Text('Sort by Members')),
              ],
              onChanged: (value) => ref.read(myCommunitiesSortProvider.notifier).state = value!,
            ),
            IconButton(
              icon: Icon(
                searchQuery.isEmpty ? Icons.search_outlined : Icons.search,
                color: searchQuery.isEmpty 
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
            var sortedCommunities = List.from(communities);
            if (sort == 'name') {
              sortedCommunities.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            } else if (sort == 'members') {
              sortedCommunities.sort((a, b) => b.memberCount.compareTo(a.memberCount));
            }

            final filteredCommunities = searchQuery.isEmpty 
                ? sortedCommunities 
                : sortedCommunities.where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()) || c.description.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            
            if (filteredCommunities.isEmpty) {
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

            // Horizontal list for compact view (limit to first 8 for UX)
            final displayedCommunities = filteredCommunities.take(8).toList();
            return Column(
              children: [
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayedCommunities.length,
                    itemBuilder: (context, index) {
                      final community = displayedCommunities[index];
                      final isInterestMatch = user != null && (userInterestsAsync.value ?? {}).any((interest) =>
                        community.tags.contains(interest) ||
                        community.name.toLowerCase().contains(interest.toLowerCase()) ||
                        community.description.toLowerCase().contains(interest.toLowerCase()));
                      return GestureDetector(
                        onTap: () {
                          NavigationService.trackUserEngagement('recommended_community_tap', parameters: {'community_id': community.id});
                          NavigationService.navigateToCommunityDetails(community.id);
                        },
                        child: Semantics(
                          label: 'Community ${community.name} with ${community.memberCount} members${isInterestMatch ? ', interest match' : ''}',
                          child: SizedBox(
                            width: 150,
                            child: Animate(
                              effects: [FadeEffect(duration: 300.ms)],
                              child: _buildEnhancedCommunityCard(context, community, false, false, isInterestMatch),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (filteredCommunities.length > 8) TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/my-communities');
                  },
                  child: const Text('See All My Communities'),
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
    final searchQuery = ref.watch(type == 'my' ? myCommunitiesSearchQueryProvider : exploreCommunitiesSearchQueryProvider);
    if (searchQuery.isNotEmpty) {
      ref.read(type == 'my' ? myCommunitiesSearchQueryProvider.notifier : exploreCommunitiesSearchQueryProvider.notifier).state = '';
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

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final userInterestsAsync = ref.watch(userInterestsProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Communities'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('All Communities'),
                  onTap: () {
                    ref.read(exploreFilterProvider.notifier).state = null;
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Recommended'),
                  onTap: () {
                    ref.read(exploreFilterProvider.notifier).state = 'recommended';
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Trending'),
                  onTap: () {
                    ref.read(exploreFilterProvider.notifier).state = 'trending';
                    Navigator.pop(context);
                  },
                ),
                if (userInterestsAsync.value?.isNotEmpty ?? false)
                  ...userInterestsAsync.value!.take(5).map((interest) => ListTile(
                    title: Text('Interest: $interest'),
                    onTap: () {
                      ref.read(exploreFilterProvider.notifier).state = interest;
                      Navigator.pop(context);
                    },
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedExploreCommunities(BuildContext context, PaginatedCommunitiesState state, WidgetRef ref, UserModel? user) {
    final searchQuery = ref.watch(exploreCommunitiesSearchQueryProvider);
    final recommendedAsync = ref.watch(recommendedCommunitiesProvider);
    final trendingAsync = ref.watch(trendingCommunitiesProvider);
    final userInterestsAsync = ref.watch(userInterestsProvider);
    final selectedFilter = ref.watch(exploreFilterProvider);

    // Apply filter based on user interests or selected filter, excluding user's communities unless searched
    List<CommunityModel> filteredCommunities = state.communities.where((community) {
      final isMember = user != null && community.isMember(user.id);
      if (searchQuery.isNotEmpty) return !isMember; // Allow all in search results
      return !isMember; // Exclude user's communities by default
    }).toList();

    if (selectedFilter != null) {
      filteredCommunities = filteredCommunities.where((community) {
        return community.tags.contains(selectedFilter) ||
               community.name.toLowerCase().contains(selectedFilter.toLowerCase()) ||
               community.description.toLowerCase().contains(selectedFilter.toLowerCase());
      }).toList();
    } else if (searchQuery.isEmpty && (userInterestsAsync.value?.isNotEmpty ?? false)) {
      final interests = userInterestsAsync.value!;
      filteredCommunities = filteredCommunities.where((community) {
        return interests.any((interest) =>
          community.tags.contains(interest) ||
          community.name.toLowerCase().contains(interest.toLowerCase()) ||
          community.description.toLowerCase().contains(interest.toLowerCase()));
      }).toList();
    } else if (searchQuery.isNotEmpty) {
      filteredCommunities = filteredCommunities.where((community) {
        return community.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               community.description.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search icon and filter button
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
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _showInlineSearch(context, ref, 'explore'),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () => _showFilterDialog(context, ref),
            ),
          ],
        ),
        
        // Inline search bar (appears when search is active) with interest suggestions
        if (searchQuery.isNotEmpty) ...[
          const SizedBox(height: AppConstants.smallPadding),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                    decoration: InputDecoration(
                      hintText: 'Search explore communities...',
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: userInterestsAsync.value?.isNotEmpty ?? false
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down, size: 16),
                              onSelected: (value) {
                                ref.read(exploreCommunitiesSearchQueryProvider.notifier).state = value;
                              },
                              itemBuilder: (context) => (userInterestsAsync.value ?? {}).take(5).map((interest) {
                                return PopupMenuItem<String>(
                                  value: interest,
                                  child: Text(interest),
                                );
                              }).toList(),
                            )
                          : null,
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
        
        // Error state
        if (state.error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading communities',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(paginatedCommunitiesProvider.notifier).clearError();
                    ref.read(paginatedCommunitiesProvider.notifier).loadInitial();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
        ],
        
        // Communities grid with personalization
        if (filteredCommunities.isEmpty && !state.isLoading && !state.isRefreshing) ...[
          // Empty state
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No communities found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to create a community!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filteredCommunities.length + (state.hasMore && state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < filteredCommunities.length) {
                final community = filteredCommunities[index];
                final isRecommended = recommendedAsync.value?.contains(community) ?? false;
                final isTrending = trendingAsync.value?.contains(community) ?? false;
                return GestureDetector(
                  onTap: () {
                    NavigationService.trackUserEngagement('community_tap', parameters: {'community_id': community.id});
                    NavigationService.navigateToCommunityDetails(community.id);
                  },
                  child: Semantics(
                    label: 'Community ${community.name} with ${community.memberCount} members${isRecommended ? ', recommended' : ''}${isTrending ? ', trending' : ''}',
                    child: Animate(
                      effects: [FadeEffect(duration: 300.ms)],
                      child: _buildEnhancedCommunityCard(context, community, isRecommended, isTrending, false),
                    ),
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        ],
        
        // Loading state for initial load or refresh
        if ((state.isLoading || state.isRefreshing) && state.communities.isEmpty) ...[
          const SizedBox(height: 32),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildEnhancedCommunityCard(BuildContext context, CommunityModel community, bool isRecommended, bool isTrending, bool isInterestMatch) {
    // Ignore isInterestMatch since it's handled by filters
    Widget? primaryBadge;
    if (isRecommended) {
      primaryBadge = Positioned(
        top: 8,
        left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Recommended',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else if (isTrending) {
      primaryBadge = Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Trending',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: community.coverImage.isNotEmpty 
                    ? CachedNetworkImage(
                        imageUrl: community.coverImage,
                        height: 60,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => _buildDefaultCover(context),
                      )
                    : _buildDefaultCover(context),
              ),
              if (primaryBadge != null) primaryBadge,
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${community.memberCount} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Icon(
        Icons.group,
        size: 30,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}