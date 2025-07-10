import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';
import '../models/community_model.dart';

// User role provider for role-based UI
final userRoleProvider = FutureProvider<String>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserRole();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final userRoleAsync = ref.watch(userRoleProvider);
    final publicCommunitiesAsync = ref.watch(publicCommunitiesProvider({'limit': 5}));
    final userCommunitiesAsync = ref.watch(userCommunitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppTheme.neutralWhite,
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
      body: userAsync.when(
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
                const SizedBox(height: AppConstants.largePadding),
                
                // Challenge Hub Section
                _buildChallengeHub(context),
                const SizedBox(height: AppConstants.largePadding),
                
                // Public Communities Section
                _buildPublicCommunities(context, publicCommunitiesAsync),
                const SizedBox(height: AppConstants.largePadding),
                
                // My Communities Section (hidden for anonymous users)
                userRoleAsync.when(
                  data: (role) => role != 'anonymous' 
                      ? _buildMyCommunities(context, userCommunitiesAsync)
                      : const SizedBox(),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
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
                color: AppTheme.errorColor,
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
                  color: AppTheme.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: userRoleAsync.when(
        data: (role) => role != 'anonymous'
            ? FloatingActionButton(
                onPressed: () {
                  NavigationService.navigateToCreateCommunity();
                },
                backgroundColor: const Color(AppColors.primaryGreen),
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
                  ? AppTheme.primaryOrange 
                  : AppTheme.primaryBlue,
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
                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
                          ? AppTheme.primaryOrange 
                          : const Color(AppColors.primaryGreen),
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
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.neutralLightGray,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: AppTheme.primaryOrange,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                const Text(
                  'Challenge Hub',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Complete challenges to earn points!',
                  style: TextStyle(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Sign up to participate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
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

    Widget _buildPublicCommunities(BuildContext context, AsyncValue<List<CommunityModel>> communitiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Public Communities',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        SizedBox(
          height: 120,
          child: communitiesAsync.when(
            data: (communities) {
              if (communities.isEmpty) {
                return const Center(
                  child: Text('No public communities available'),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: AppConstants.smallPadding),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.smallPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              community.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.onSurfaceColor.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 12,
                                  color: AppTheme.onSurfaceColor.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${community.memberCount} members',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                NavigationService.navigateToCommunityDetails(community.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(AppColors.primaryBlue),
                                minimumSize: const Size(double.infinity, 32),
                              ),
                              child: const Text(
                                'View',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
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
              child: Text('Error loading communities: $error'),
            ),
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
        SizedBox(
          height: 120,
          child: communitiesAsync.when(
            data: (communities) {
              if (communities.isEmpty) {
                return const Center(
                  child: Text('You haven\'t joined any communities yet'),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: AppConstants.smallPadding),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.smallPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              community.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.onSurfaceColor.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 12,
                                  color: AppTheme.onSurfaceColor.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${community.memberCount} members',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                NavigationService.navigateToCommunityDetails(community.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(AppColors.primaryGreen),
                                minimumSize: const Size(double.infinity, 32),
                              ),
                              child: const Text(
                                'Open',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
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
              child: Text('Error loading communities: $error'),
            ),
          ),
        ),
      ],
    );
  }
} 