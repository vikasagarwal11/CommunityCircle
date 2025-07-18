import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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
import '../widgets/welcome_flash_screen.dart';
import '../models/event_model.dart';
import '../providers/event_providers.dart';

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
    final user = userAsync.value;
    final isGuest = user == null || user.role == 'anonymous';

    return DefaultTabController(
      length: isGuest ? 1 : _getTabCount(membershipAsync),
      child: Scaffold(
        appBar: _buildAppBar(context, ref, community, userAsync),
        body: Column(
          children: [
            _buildCommunityHeader(context, community),
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
    return HookConsumer(
      builder: (context, ref, child) {
        final isExpanded = useState(false);
        final showDescription = useState(false);
        
        return Container(
          height: isExpanded.value ? (showDescription.value ? 280 : 200) : 120,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              community.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              isExpanded.value = !isExpanded.value;
                              if (isExpanded.value) {
                                showDescription.value = true;
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${community.memberCount} members',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            community.visibility == 'public' ? Icons.public : Icons.lock,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            community.visibility,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      if (isExpanded.value && showDescription.value)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(top: 8),
                          child: Text(
                            community.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  List<Widget> _buildTabsAndViews(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
    {bool forTabs = true}
  ) {
    final tabs = <Widget>[
      const Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
      const Tab(text: 'Events', icon: Icon(Icons.event_outlined)),
      const Tab(text: 'Members', icon: Icon(Icons.people_outline)),
    ];
    final views = <Widget>[
      _buildOverviewTab(context, ref, community),
      _buildEventsTab(context, ref, community),
      _buildMembersTab(context, ref, community),
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

  Widget _buildOverviewTab(BuildContext context, WidgetRef ref, CommunityModel community) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          Text(
            'Community Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            community.description,
            style: Theme.of(context).textTheme.bodyMedium,
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
          Container(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, color: Theme.of(context).colorScheme.primary),
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
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.event_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Events are coming soon!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                    child: Text(
                      'You\'ll soon be able to create, join, and manage community events right here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildMembersTab(BuildContext context, WidgetRef ref, CommunityModel community) {
    final membersAsync = ref.watch(communityMembersProvider(community.id));
    final currentUserAsync = ref.watch(authNotifierProvider);
    final searchQuery = ref.watch(memberSearchProvider(community.id));

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Enhanced header with search icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Members',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      membersAsync.when(
                        data: (members) => Text(
                          '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        loading: () => Text(
                          'Loading...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        error: (_, __) => Text(
                          'Error loading',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search icon button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () => _showSearchDialog(context, ref, community),
                    tooltip: 'Search members',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search results indicator with enhanced design
          if (searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search results',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  membersAsync.when(
                    data: (members) {
                      final filteredMembers = ref.watch(filteredMembersProvider(community.id));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${filteredMembers.length} found',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Enhanced members list
          Expanded(
            child: membersAsync.when(
              data: (members) {
                final filteredMembers = ref.watch(filteredMembersProvider(community.id));
                
                if (filteredMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty ? 'No members found' : 'No members yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isNotEmpty 
                              ? 'Try adjusting your search terms'
                              : 'Be the first to join this community!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    final isCurrentUser = currentUserAsync.value?.id == member.id;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            child: member.profilePictureUrl != null && member.profilePictureUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      member.profilePictureUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.person_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.displayName ?? 'Anonymous User',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isCurrentUser)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'You',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            if (member.id == community.adminUid)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Admin',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Joined ${_formatJoinDate(member.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        trailing: isCurrentUser
                            ? null
                            : Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  onPressed: () => _showMemberOptions(context, ref, member, community),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load members',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
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
    );
  }

  // Search dialog method
  void _showSearchDialog(BuildContext context, WidgetRef ref, CommunityModel community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Search Members'),
          ],
        ),
        content: HookConsumer(
          builder: (context, ref, child) {
            final searchController = useTextEditingController();
            final debounceTimer = useState<Timer?>(null);
            
            useEffect(() {
              void updateSearch() {
                final query = searchController.text;
                ref.read(memberSearchProvider(community.id).notifier).state = query;
                
                debounceTimer.value?.cancel();
                debounceTimer.value = Timer(const Duration(milliseconds: 300), () {
                  ref.read(debouncedSearchProvider(community.id).notifier).state = query;
                });
              }
              
              searchController.addListener(updateSearch);
              return () {
                searchController.removeListener(updateSearch);
                debounceTimer.value?.cancel();
              };
            }, [searchController]);
            
            return TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search members by name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          searchController.clear();
                          ref.read(memberSearchProvider(community.id).notifier).state = '';
                          ref.read(debouncedSearchProvider(community.id).notifier).state = '';
                        },
                      )
                    : null,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                _buildAdminCard(
                  context,
                  'Community Settings',
                  'Edit community details and rules',
                  Icons.settings,
                  () => _showCommunitySettings(context, community),
                ),
                _buildAdminCard(
                  context,
                  'Analytics',
                  'View community statistics and insights',
                  Icons.analytics,
                  () => _showAnalytics(context, community),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
  ) {
    return membershipAsync.when(
      data: (membership) {
        if (membership == 'admin') {
          return FloatingActionButton(
            onPressed: () => _showAdminActions(context, ref, community),
            child: const Icon(Icons.add),
          );
        }
        return null;
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  int _getTabCount(AsyncValue<String> membershipAsync) {
    return membershipAsync.when(
      data: (membership) => membership == 'admin' ? 4 : 3,
      loading: () => 3,
      error: (_, __) => 3,
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks} ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months} ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String value, CommunityModel community) {
    switch (value) {
      case 'share':
        // TODO: Implement share functionality
        break;
      case 'report':
        // TODO: Implement report functionality
        break;
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context, WidgetRef ref, CommunityModel community) {
    return [
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
    ];
  }

  void _showMemberOptions(BuildContext context, WidgetRef ref, UserModel member, CommunityModel community) {
    // TODO: Implement member options
  }

  void _showMemberManagement(BuildContext context, CommunityModel community) {
    // TODO: Implement member management
  }

  void _showCommunitySettings(BuildContext context, CommunityModel community) {
    // TODO: Implement community settings
  }

  void _showAnalytics(BuildContext context, CommunityModel community) {
    // TODO: Implement analytics
  }

  void _showAdminActions(BuildContext context, WidgetRef ref, CommunityModel community) {
    // TODO: Implement admin actions
  }
} 