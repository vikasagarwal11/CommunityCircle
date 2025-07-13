import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/join_questions_dialog.dart';
import '../widgets/welcome_onboarding_dialog.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';

// Enhanced community provider with real-time updates
final communityProvider = StreamProvider.family<CommunityModel?, String>((ref, communityId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.communitiesCollection)
      .doc(communityId)
      .snapshots()
      .map((doc) {
    if (doc.exists) {
      return CommunityModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  });
});

// User membership status provider
final userMembershipProvider = StreamProvider.family<String, String>((ref, communityId) {
  final userAsync = ref.watch(authNotifierProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value('none');
      
      return FirebaseFirestore.instance
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return 'none';
        
        final data = doc.data()!;
        final members = List<String>.from(data['members'] ?? []);
        final bannedUsers = List<String>.from(data['banned_users'] ?? []);
        final adminUid = data['admin_uid'] ?? '';
        
        if (bannedUsers.contains(user.id)) return 'banned';
        if (adminUid == user.id) return 'admin';
        if (members.contains(user.id)) return 'member';
        return 'none';
      });
    },
    loading: () => Stream.value('loading'),
    error: (_, __) => Stream.value('error'),
  );
});

class CommunityDetailsScreen extends ConsumerWidget {
  final String communityId;
  
  const CommunityDetailsScreen({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(communityDetailsProvider(communityId));
    final userAsync = ref.watch(authNotifierProvider);
    final membershipAsync = ref.watch(communityMembershipProvider(communityId));

    return Scaffold(
      body: communityAsync.when(
        data: (community) {
          if (community == null) {
            return const CustomErrorWidget(
              message: 'Community not found',
              icon: Icons.group_off,
            );
          }

          return _buildCommunityContent(context, ref, community, userAsync, membershipAsync);
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load community',
          error: error.toString(),
        ),
      ),
    );
  }

  // NEW: Check and show onboarding for existing members
  void _checkAndShowOnboarding(BuildContext context, WidgetRef ref, CommunityModel community) {
    final userAsync = ref.read(authNotifierProvider);
    userAsync.when(
      data: (user) {
        if (user != null && community.isMember(user.id)) {
          // Check if user has completed onboarding
          ref.read(userOnboardingStatusProvider({
            'communityId': community.id,
            'userId': user.id,
          })).when(
            data: (hasCompleted) {
              if (!hasCompleted) {
                // Show onboarding for existing member who hasn't completed it
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => WelcomeOnboardingDialog(
                      community: community,
                      user: user,
                      onComplete: () {
                        // Mark onboarding as completed
                        ref.read(communityActionsProvider.notifier).completeOnboarding(
                          community.id,
                          user.id,
                        );
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Welcome back! 🎉'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  );
                });
              }
            },
            loading: () => null,
            error: (_, __) => null,
          );
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  Widget _buildCommunityContent(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<UserModel?> userAsync,
    AsyncValue<String> membershipAsync,
  ) {
    // NEW: Check for onboarding on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding(context, ref, community);
    });

    final user = userAsync.value;
    final isGuest = user == null || user.role == 'anonymous';

    return DefaultTabController(
      length: isGuest ? 1 : _getTabCount(membershipAsync),
      child: Scaffold(
        appBar: _buildAppBar(context, ref, community, userAsync),
        body: Column(
          children: [
            _buildCommunityHeader(context, community),
            // Only show welcome message if user is a member
            if (!isGuest && community.isMember(user?.id ?? ''))
              _buildWelcomeMessageSection(context, community),
            // Remove rules from here; will be shown in join sheet only
            if (isGuest)
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members: ${community.memberCount}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign In Required'),
                            content: const Text('Please sign in to join and participate in this community.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  NavigationService.navigateToPhoneAuth();
                                },
                                child: const Text('Sign In'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In to Join'),
                    ),
                  ],
                ),
              )
            else ...[
              _buildTabBar(context, ref, community, membershipAsync),
              Expanded(
                child: _buildTabBarView(context, ref, community, membershipAsync),
              ),
            ],
          ],
        ),
        floatingActionButton: isGuest ? null : _buildFloatingActionButton(context, ref, community, membershipAsync),
      ),
    );
  }

  // NEW: Rules display section
  Widget _buildRulesSection(BuildContext context, CommunityModel community) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rule,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Text(
                'Community Rules',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${community.rules.length} rules',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          ...community.rules.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      rule,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // NEW: Welcome message display section
  Widget _buildWelcomeMessageSection(BuildContext context, CommunityModel community) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waving_hand,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Text(
                'Welcome Message',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'From Admin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            community.welcomeMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<UserModel?> userAsync,
  ) {
    return AppBar(
      title: Text(community.name),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => NavigationService.goBack(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, ref, value, community),
          itemBuilder: (context) => _buildMenuItems(context, ref, community),
        ),
      ],
    );
  }

  Widget _buildCommunityHeader(BuildContext context, CommunityModel community) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Cover image
          if (community.coverImage.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.network(
                  community.coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          // Community info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: NavigationService.navigatorKey.currentContext!,
                        builder: (context) => AlertDialog(
                          title: Text(community.name),
                          content: Text(community.description),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      community.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${community.members.length} members',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppConstants.defaultPadding),
                      Icon(
                        Icons.visibility,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        community.visibility,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabsAndViews(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
    {bool forTabs = true}
  ) {
    final tabs = <Widget>[
      const Tab(text: 'Chat', icon: Icon(Icons.chat_bubble_outline)),
      const Tab(text: 'Events', icon: Icon(Icons.event_outlined)),
    ];
    final views = <Widget>[
      _buildChatTab(context, ref, community),
      _buildEventsTab(context, ref, community),
    ];
    membershipAsync.when(
      data: (membership) {
        if (membership == 'admin') {
          tabs.add(const Tab(text: 'Admin', icon: Icon(Icons.admin_panel_settings_outlined)));
          views.addAll(_buildAdminTabs(context, ref, community, membershipAsync));
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
    return forTabs ? tabs : views;
  }

  Widget _buildTabBar(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
  ) {
    return membershipAsync.when(
      data: (membership) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            isScrollable: true,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            tabs: _buildTabsAndViews(context, ref, community, AsyncValue.data(membership), forTabs: true),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }



  Widget _buildTabBarView(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
  ) {
    return membershipAsync.when(
      data: (membership) {
        final views = _buildTabsAndViews(context, ref, community, AsyncValue.data(membership), forTabs: false);
        return TabBarView(children: views);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading tabs')),
    );
  }

  Widget _buildChatTab(BuildContext context, WidgetRef ref, CommunityModel community) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Community Chat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${community.members.length} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          // Chat messages placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                  Text(
                    'Join the conversation!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Connect with ${community.members.length} members',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        NavigationService.navigateToChat(community.id);
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Open Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.defaultPadding,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(BuildContext context, WidgetRef ref, CommunityModel community) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Events header
          Container(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Upcoming Events',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '0 events',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          // Events list placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'No events yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Create the first event for this community',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAdminTabs(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
  ) {
    return membershipAsync.when(
      data: (membership) {
        if (membership == 'admin') {
          return [_buildAdminTab(context, ref, community)];
        }
        return [];
      },
      loading: () => [const Center(child: CircularProgressIndicator())],
      error: (_, __) => [const Center(child: Text('Error loading admin tab'))],
    );
  }

  Widget _buildAdminTab(BuildContext context, WidgetRef ref, CommunityModel community) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Admin Panel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${community.members.length} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Expanded(
            child: ListView(
              children: [
                _buildAdminCard(
                  context,
                  'Manage Members',
                  'Add, remove, or ban community members',
                  Icons.people_outline,
                  () => _showMemberManagement(context, community),
                ),
                // NEW: Join Requests Review
                if (community.approvalRequired || community.hasJoinQuestions)
                  _buildAdminCard(
                    context,
                    'Join Requests',
                    'Review pending join requests and answers',
                    Icons.pending_actions,
                    () => _showJoinRequestsReview(context, ref, community),
                  ),
                _buildAdminCard(
                  context,
                  'Community Settings',
                  'Edit community details and privacy',
                  Icons.settings_outlined,
                  () => _showCommunitySettings(context, community),
                ),
                _buildAdminCard(
                  context,
                  'Analytics',
                  'View community engagement metrics',
                  Icons.analytics_outlined,
                  () => _showAnalytics(context, community),
                ),
                _buildAdminCard(
                  context,
                  'Moderation',
                  'Manage reported content and users',
                  Icons.shield_outlined,
                  () => _showModeration(context, community),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
  ) {
    return membershipAsync.when(
      data: (membership) {
        if (membership == 'none') {
          return FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).colorScheme.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: JoinCommunitySheet(
                    community: community,
                    ref: ref,
                    onJoined: () {
                      ScaffoldMessenger.of(context).clearMaterialBanners();
                      ScaffoldMessenger.of(context).showMaterialBanner(
                        MaterialBanner(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Welcome to the community! 🎉',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
                              child: Text('Dismiss', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            ),
                          ],
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.secondary,
            icon: Icon(
              community.hasJoinQuestions ? Icons.question_answer : Icons.add,
              color: Colors.white,
            ),
            label: const Text('Join', style: TextStyle(color: Colors.white)),
          );
        }
        
        return FloatingActionButton(
          onPressed: () => _showActionSheet(context, ref, community, membership),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  int _getTabCount(AsyncValue<String> membershipAsync) {
    return membershipAsync.when(
      data: (membership) {
        int count = 2; // Chat and Events always visible
        if (membership == 'admin') {
          count += 1; // Admin tab
        }
        return count;
      },
      loading: () => 2, // Default to 2 tabs while loading
      error: (_, __) => 2, // Default to 2 tabs on error
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    final items = <PopupMenuEntry<String>>[];
    
    // Share community
    items.add(
      const PopupMenuItem(
        value: 'share',
        child: Row(
          children: [
            Icon(Icons.share),
            SizedBox(width: 8),
            Text('Share Community'),
          ],
        ),
      ),
    );
    
    // Report community
    items.add(
      const PopupMenuItem(
        value: 'report',
        child: Row(
          children: [
            Icon(Icons.report),
            SizedBox(width: 8),
            Text('Report Community'),
          ],
        ),
      ),
    );
    
    return items;
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    CommunityModel community,
  ) {
    switch (action) {
      case 'share':
        _shareCommunity(context, community);
        break;
      case 'report':
        _reportCommunity(context, community);
        break;
    }
  }

  void _showSearchDialog(BuildContext context, CommunityModel community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Community'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Search messages, events, members...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationService.goBack(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              NavigationService.goBack();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _shareCommunity(BuildContext context, CommunityModel community) {
    NavigationService.showSnackBar(
      message: 'Sharing ${community.name}',
    );
  }

  void _joinCommunity(BuildContext context, WidgetRef ref, CommunityModel community) {
    final logger = Logger();
    // Helper to show rules acknowledgment dialog
    void showRulesDialog({required VoidCallback onAcknowledge}) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          bool acknowledged = false;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.rule, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Community Rules'),
                ],
              ),
              content: SizedBox(
                width: 350,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...community.rules.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: acknowledged,
                            onChanged: (val) => setState(() => acknowledged = val ?? false),
                          ),
                          const Expanded(
                            child: Text('I acknowledge and agree to these rules.'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: acknowledged
                      ? () async {
                          Navigator.of(context).pop();
                          logger.i('User acknowledged rules for community: ${community.id}');
                          await ref.read(communityActionsProvider.notifier).acknowledgeRules(
                            community.id,
                            community.rules,
                          );
                          onAcknowledge();
                        }
                      : null,
                  child: const Text('Agree & Join'),
                ),
              ],
            ),
          );
        },
      );
    }

    // Helper to show onboarding dialog after successful join
    void showOnboardingDialog() {
      final userAsync = ref.read(authNotifierProvider);
      userAsync.when(
        data: (user) {
          if (user != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => WelcomeOnboardingDialog(
                community: community,
                user: user,
                onComplete: () {
                  // Mark onboarding as completed
                  ref.read(communityActionsProvider.notifier).completeOnboarding(
                    community.id,
                    user.id,
                  );
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Welcome to the community! 🎉'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            );
          }
        },
        loading: () => null,
        error: (_, __) => null,
      );
    }

    // If community has join questions, show that first
    if (community.hasJoinQuestions) {
      logger.i('Join flow: community has join questions.');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => JoinQuestionsDialog(
          questions: community.joinQuestions,
          onSubmit: (answers) async {
            logger.i('Join flow: user submitted join answers: $answers');
            // After join questions, show rules dialog if needed
            if (community.hasRules) {
              showRulesDialog(onAcknowledge: () async {
                try {
                  logger.i('Join flow: user acknowledged rules, joining with answers.');
                  await ref.read(communityActionsProvider.notifier).joinCommunityWithAnswers(
                    community.id,
                    answers,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    showOnboardingDialog(); // Show onboarding after successful join
                  }
                } catch (e, stack) {
                  logger.e('Join flow error (joinCommunityWithAnswers after rules): $e\n$stack');
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to join: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              });
            } else {
              // No rules, join directly
              try {
                logger.i('Join flow: joining with answers, no rules.');
                await ref.read(communityActionsProvider.notifier).joinCommunityWithAnswers(
                  community.id,
                  answers,
                );
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  showOnboardingDialog(); // Show onboarding after successful join
                }
              } catch (e, stack) {
                logger.e('Join flow error (joinCommunityWithAnswers direct): $e\n$stack');
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to join: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          onCancel: () {
            logger.i('Join flow: user cancelled join questions dialog.');
            Navigator.of(context).pop(); // Close dialog
          },
        ),
      );
    } else if (community.hasRules) {
      logger.i('Join flow: community has rules, no join questions.');
      // No join questions, but has rules
      showRulesDialog(onAcknowledge: () async {
        try {
          logger.i('Join flow: user acknowledged rules, joining.');
          await ref.read(communityActionsProvider.notifier).joinCommunity(community.id);
          if (context.mounted) {
            showOnboardingDialog(); // Show onboarding after successful join
          }
        } catch (e, stack) {
          logger.e('Join flow error (joinCommunity after rules): $e\n$stack');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to join: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    } else {
      logger.i('Join flow: instant join, no questions or rules.');
      // Regular join without questions or rules
      ref.read(communityActionsProvider.notifier).joinCommunity(community.id).then((_) {
        showOnboardingDialog(); // Show onboarding after successful join
      }).catchError((e, stack) {
        logger.e('Join flow error (instant join): $e\n$stack');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  void _showActionSheet(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    String membership,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Send Message'),
              onTap: () {
                NavigationService.goBack();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on_outlined),
              title: const Text('Create Moment'),
              onTap: () {
                NavigationService.goBack();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Moments coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Create Event'),
              onTap: () {
                NavigationService.goBack();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Events coming soon!')),
                );
              },
            ),
            if (membership == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Actions'),
                onTap: () {
                  NavigationService.goBack();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin panel coming soon!')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMemberManagement(BuildContext context, CommunityModel community) {
    NavigationService.navigateToAdminManagement(community);
  }

  void _showCommunitySettings(BuildContext context, CommunityModel community) {
    NavigationService.navigateToAdminManagement(community);
  }

  void _showAnalytics(BuildContext context, CommunityModel community) {
    NavigationService.navigateToAdminManagement(community);
  }

  void _showModeration(BuildContext context, CommunityModel community) {
    NavigationService.navigateToAdminManagement(community);
  }

  void _showJoinRequestsReview(BuildContext context, WidgetRef ref, CommunityModel community) {
    NavigationService.navigateToJoinRequestsReview(community);
  }

  void _reportCommunity(BuildContext context, CommunityModel community) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted')),
    );
  }
} 

class JoinCommunitySheet extends StatefulWidget {
  final CommunityModel community;
  final void Function()? onJoined;
  final WidgetRef ref;

  const JoinCommunitySheet({
    super.key,
    required this.community,
    required this.ref,
    this.onJoined,
  });

  @override
  State<JoinCommunitySheet> createState() => _JoinCommunitySheetState();
}

class _JoinCommunitySheetState extends State<JoinCommunitySheet> {
  final _formKey = GlobalKey<FormState>();
  late List<TextEditingController> _answerControllers;
  bool _acknowledgedRules = false;
  bool _joining = false;
  bool _joined = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _answerControllers = List.generate(
      widget.community.joinQuestions.length,
      (i) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleJoin() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    final logger = Logger();
    try {
      final answers = _answerControllers.map((c) => c.text.trim()).toList();
      final hasQuestions = widget.community.hasJoinQuestions;
      // No longer require rules acknowledgment
      // Always allow skip
      if (hasQuestions && answers.any((a) => a.isEmpty)) {
        setState(() {
          _joining = false;
          _error = 'Please answer all questions or tap Skip.';
        });
        return;
      }
      if (hasQuestions) {
        await widget.ref.read(communityActionsProvider.notifier).joinCommunityWithAnswers(
          widget.community.id,
          answers,
        );
      } else {
        await widget.ref.read(communityActionsProvider.notifier).joinCommunity(widget.community.id);
      }
      setState(() {
        _joined = true;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (widget.onJoined != null) widget.onJoined!();
      Navigator.of(context).pop();
      // Show success MaterialBanner (handled in parent)
    } catch (e, stack) {
      logger.e('JoinCommunitySheet error: $e\n$stack');
      setState(() {
        _joining = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuestions = widget.community.hasJoinQuestions;
    final hasRules = widget.community.hasRules;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Join ${widget.community.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (hasQuestions) ...[
                  Text('Answer a few questions (optional):', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  ...List.generate(widget.community.joinQuestions.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      controller: _answerControllers[i],
                      decoration: InputDecoration(
                        labelText: widget.community.joinQuestions[i],
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                if (hasRules) ...[
                  Text('Community Rules:', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  ...List.generate(widget.community.rules.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ', style: Theme.of(context).textTheme.bodySmall),
                        Expanded(child: Text(widget.community.rules[i], style: Theme.of(context).textTheme.bodySmall)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _joining ? null : _handleJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _joined ? Colors.green : Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _joining
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_joined ? 'Joined!' : 'Join Now'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 