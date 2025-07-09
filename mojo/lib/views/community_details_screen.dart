import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../providers/database_providers.dart';
import '../services/auth_service.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

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

  Widget _buildCommunityContent(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<UserModel?> userAsync,
    AsyncValue<String> membershipAsync,
  ) {
    return DefaultTabController(
      length: _getTabCount(membershipAsync),
      child: Scaffold(
        appBar: _buildAppBar(context, ref, community, userAsync),
        body: Column(
          children: [
            _buildCommunityHeader(context, community),
            _buildTabBar(context, membershipAsync),
            Expanded(
              child: _buildTabBarView(context, ref, community, membershipAsync),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context, ref, community, membershipAsync),
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
      backgroundColor: AppTheme.neutralWhite,
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
            AppTheme.primaryBlue.withOpacity(0.8),
            AppTheme.primaryBlue.withOpacity(0.4),
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
                    color: AppTheme.neutralLightGray,
                    child: const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: AppTheme.onSurfaceColor,
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
                    Colors.black.withOpacity(0.7),
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
                  Text(
                    community.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildTabBar(
    BuildContext context,
    AsyncValue<String> membershipAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutralWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        isScrollable: true,
        indicatorColor: AppTheme.primaryBlue,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.onSurfaceColor,
        tabs: _buildTabs(membershipAsync),
      ),
    );
  }

  List<Widget> _buildTabs(
    AsyncValue<String> membershipAsync,
  ) {
    final tabs = <Widget>[
      const Tab(text: 'Chat', icon: Icon(Icons.chat_bubble_outline)),
      const Tab(text: 'Events', icon: Icon(Icons.event_outlined)),
    ];

    // Add admin-only tabs
    membershipAsync.when(
      data: (membership) {
        if (membership == 'admin') {
          tabs.add(const Tab(text: 'Admin', icon: Icon(Icons.admin_panel_settings_outlined)));
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );

    return tabs;
  }

  Widget _buildTabBarView(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
  ) {
    return TabBarView(
      children: [
        // Chat Tab
        _buildChatTab(context, ref, community),
        // Events Tab
        _buildEventsTab(context, ref, community),
        // Admin tabs
        ..._buildAdminTabs(context, ref, community, membershipAsync),
      ],
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
              color: AppTheme.neutralLightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryBlue),
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
                    color: AppTheme.onSurfaceColor,
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
                    'Join the conversation!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Connect with ${community.members.length} members',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
                        backgroundColor: AppTheme.primaryBlue,
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
              color: AppTheme.neutralLightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined, color: AppTheme.primaryOrange),
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
                    color: AppTheme.onSurfaceColor,
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
                    color: AppTheme.onSurfaceColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'No events yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Create the first event for this community',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
              color: AppTheme.neutralLightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primaryRed),
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
                    color: AppTheme.onSurfaceColor,
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
        leading: Icon(icon, color: AppTheme.primaryBlue),
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
            onPressed: () => _joinCommunity(context, ref, community),
            backgroundColor: const Color(AppColors.primaryGreen),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Join Community',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        
        return FloatingActionButton(
          onPressed: () => _showActionSheet(context, ref, community, membership),
          backgroundColor: const Color(AppColors.primaryBlue),
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  int _getTabCount(AsyncValue<String> membershipAsync) {
    int count = 2; // Chat and Events always visible
    
    membershipAsync.when(
      data: (membership) {
        if (membership == 'admin') {
          count += 1; // Admin tab
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
    
    return count;
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
    ref.read(communityActionsProvider.notifier).joinCommunity(community.id);
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on_outlined),
              title: const Text('Create Moment'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Moments coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Create Event'),
              onTap: () {
                Navigator.pop(context);
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
                  Navigator.pop(context);
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

  void _reportCommunity(BuildContext context, CommunityModel community) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted')),
    );
  }
} 