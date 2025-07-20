import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'community_details_screen_overview_tab.dart';
import 'community_details_screen_events_tab.dart';
import 'community_details_screen_members_tab.dart';
import 'community_details_screen_admin_tab.dart';
import 'community_details_screen_actions.dart';
import 'community_details_screen_dialogs.dart';
import 'community_details_screen_logic.dart';

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
    final isGuest = CommunityDetailsLogic.isGuest(user);

    return DefaultTabController(
      length: isGuest ? 1 : CommunityDetailsLogic.getTabCount(membershipAsync),
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
                        CommunityDetailsDialogs.showSignInRequiredDialog(context);
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
        floatingActionButton: isGuest ? null : buildCommunityDetailsFAB(context, ref, community, membershipAsync),
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
          onSelected: (value) => CommunityDetailsLogic.handleMenuAction(context, ref, value, community),
          itemBuilder: (context) => CommunityDetailsLogic.buildMenuItems(context, ref, community),
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
          height: 80,
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
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              child: Text(
                community.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
      OverviewTab(community: community),
      EventsTab(community: community),
      MembersTab(community: community),
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

  List<Widget> _buildAdminTabs(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
    AsyncValue<String> membershipAsync,
  ) {
    return membershipAsync.when(
      data: (membership) {
        if (membership == 'admin') {
          return [AdminTab(community: community)];
        }
        return [];
      },
      loading: () => [const Center(child: CircularProgressIndicator())],
      error: (_, __) => [const Center(child: Text('Error loading admin tab'))],
    );
  }

  int _getTabCount(AsyncValue<String> membershipAsync) {
    return membershipAsync.when(
      data: (membership) {
        if (membership == 'admin') {
          return 4; // Overview, Events, Members, Admin
        }
        return 3; // Overview, Events, Members
      },
      loading: () => 3,
      error: (_, __) => 3,
    );
  }
} 