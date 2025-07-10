import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/community_providers.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';

class AdminManagementScreen extends HookConsumerWidget {
  final CommunityModel community;
  
  const AdminManagementScreen({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0);
    final isLoading = useState(false);
    final communityAsync = ref.watch(communityDetailsProvider(community.id));
    final userAsync = ref.watch(authNotifierProvider);
    final membershipAsync = ref.watch(communityMembershipProvider(community.id));
    final communityStatsAsync = ref.watch(communityStatsProvider(community.id));
    final communityActionsAsync = ref.watch(communityActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${community.name}'),
        backgroundColor: AppTheme.neutralWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with community info
          _buildCommunityHeader(context, ref),
          
          // Tab bar
          _buildTabBar(context, selectedTab),
          
          // Tab content
          Expanded(
            child: _buildTabContent(
              context,
              ref,
              selectedTab,
              isLoading,
              userAsync,
              communityStatsAsync,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryGreen.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Community avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.primaryBlue,
                width: 2,
              ),
            ),
            child: community.coverImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(
                      community.coverImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.group,
                    color: AppTheme.primaryBlue,
                    size: 30,
                  ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
          
          // Community info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: AppTheme.onSurfaceColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${community.members.length} members',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: community.visibility == 'public'
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : AppTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        community.visibility.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: community.visibility == 'public'
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ValueNotifier<int> selectedTab) {
    final tabs = [
      'Overview',
      'Members',
      'Settings',
      'Analytics',
      'Moderation',
    ];

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = selectedTab.value == index;
            
            return GestureDetector(
              onTap: () => selectedTab.value = index,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.onSurfaceColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<int> selectedTab,
    ValueNotifier<bool> isLoading,
    AsyncValue<UserModel?> userAsync,
    AsyncValue<Map<String, dynamic>> communityStatsAsync,
  ) {
    switch (selectedTab.value) {
      case 0:
        return _buildOverviewTab(context, ref, communityStatsAsync);
      case 1:
        return _buildMembersTab(context, ref, isLoading);
      case 2:
        return _buildSettingsTab(context, ref, isLoading);
      case 3:
        return _buildAnalyticsTab(context, ref, communityStatsAsync);
      case 4:
        return _buildModerationTab(context, ref, isLoading);
      default:
        return const Center(child: Text('Tab not found'));
    }
  }

  Widget _buildOverviewTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> communityStatsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          _buildQuickStats(context, communityStatsAsync),
          const SizedBox(height: AppConstants.largePadding),
          
          // Recent activity
          _buildRecentActivity(context),
          const SizedBox(height: AppConstants.largePadding),
          
          // Quick actions
          _buildQuickActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> communityStatsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        communityStatsAsync.when(
          data: (stats) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppConstants.defaultPadding,
            mainAxisSpacing: AppConstants.defaultPadding,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                'Members',
                '${stats['member_count'] ?? 0}',
                Icons.people,
                AppTheme.primaryBlue,
              ),
              _buildStatCard(
                context,
                'Events',
                '${stats['event_count'] ?? 0}',
                Icons.event,
                AppTheme.primaryGreen,
              ),
              _buildStatCard(
                context,
                'Moments',
                '${stats['moment_count'] ?? 0}',
                Icons.flash_on,
                AppTheme.primaryOrange,
              ),
              _buildStatCard(
                context,
                'Messages',
                '${stats['message_count'] ?? 0}',
                Icons.chat,
                AppTheme.primaryPurple,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading stats')),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: AppTheme.neutralLightGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                'New member joined',
                '2 minutes ago',
                Icons.person_add,
                AppTheme.primaryGreen,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                context,
                'Event created',
                '15 minutes ago',
                Icons.event,
                AppTheme.primaryBlue,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                context,
                'Moment posted',
                '1 hour ago',
                Icons.flash_on,
                AppTheme.primaryOrange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.defaultPadding,
          mainAxisSpacing: AppConstants.defaultPadding,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              context,
              'Create Event',
              Icons.event,
              AppTheme.primaryGreen,
              () => _createEvent(context),
            ),
            _buildActionCard(
              context,
              'Send Announcement',
              Icons.announcement,
              AppTheme.primaryBlue,
              () => _sendAnnouncement(context),
            ),
            _buildActionCard(
              context,
              'Manage Members',
              Icons.people,
              AppTheme.primaryOrange,
              () => _manageMembers(context),
            ),
            _buildActionCard(
              context,
              'View Analytics',
              Icons.analytics,
              AppTheme.primaryPurple,
              () => _viewAnalytics(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context, WidgetRef ref, ValueNotifier<bool> isLoading) {
    final membersAsync = ref.watch(filteredMembersProvider(community.id));
    final selectedMembers = ref.watch(selectedMembersProvider(community.id));
    final searchQuery = ref.watch(memberSearchProvider(community.id));
    final bulkActionsAsync = ref.watch(bulkActionsProvider(community.id));

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with search and actions
          Row(
            children: [
              Expanded(
                child: Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (selectedMembers.isNotEmpty) ...[
                TextButton.icon(
                  onPressed: () => _banSelectedMembers(context, ref),
                  icon: const Icon(Icons.block, color: AppTheme.errorColor),
                  label: const Text('Ban Selected'),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                TextButton.icon(
                  onPressed: () => _removeSelectedMembers(context, ref),
                  icon: const Icon(Icons.person_remove, color: AppTheme.primaryOrange),
                  label: const Text('Remove'),
                ),
                const SizedBox(width: AppConstants.smallPadding),
              ],
              TextButton.icon(
                onPressed: () => _inviteMembers(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Invite'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Search bar
          TextField(
            onChanged: (value) {
              ref.read(memberSearchProvider(community.id).notifier).state = value;
            },
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Members list
          Expanded(
            child: membersAsync.isEmpty
                ? _buildEmptyMembersState(context, searchQuery)
                : ListView.builder(
                    itemCount: membersAsync.length,
                    itemBuilder: (context, index) {
                      final member = membersAsync[index];
                      return _buildMemberTile(context, ref, member, selectedMembers, isLoading);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMembersState(BuildContext context, String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: AppTheme.onSurfaceColor.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            searchQuery.isNotEmpty ? 'No members found' : 'No members yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceColor,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Invite members to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    WidgetRef ref,
    UserModel member,
    Set<String> selectedMembers,
    ValueNotifier<bool> isLoading,
  ) {
    final isAdmin = member.id == community.adminUid;
    final isSelected = selectedMembers.contains(member.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: isAdmin ? null : (value) {
                final newSelection = Set<String>.from(selectedMembers);
                if (value == true) {
                  newSelection.add(member.id);
                } else {
                  newSelection.remove(member.id);
                }
                ref.read(selectedMembersProvider(community.id).notifier).state = newSelection;
              },
            ),
            CircleAvatar(
              backgroundColor: isAdmin ? AppTheme.primaryRed : AppTheme.primaryBlue,
              child: Text(
                (member.displayName?.isNotEmpty == true ? member.displayName![0].toUpperCase() : '?'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        title: Text(
          member.displayName ?? '',
          style: TextStyle(
            fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdmin ? 'Community Admin' : 'Member',
              style: TextStyle(
                color: isAdmin ? AppTheme.primaryRed : AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
            ),
            Text(
              member.email ?? member.phoneNumber,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: isAdmin
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) => _handleMemberAction(context, ref, member.id, value, isLoading),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'ban',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text('Ban User'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: AppTheme.primaryOrange),
                        SizedBox(width: 8),
                        Text('Remove from Community'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, WidgetRef ref, ValueNotifier<bool> isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          
          // Basic Settings
          _buildSettingsSection(
            context,
            'Basic Settings',
            [
              _buildSettingTile(
                context,
                'Community Name',
                community.name,
                Icons.edit,
                () => _editCommunityName(context),
              ),
              _buildSettingTile(
                context,
                'Description',
                community.description,
                Icons.description,
                () => _editDescription(context),
              ),
              _buildSettingTile(
                context,
                'Cover Image',
                'Change cover image',
                Icons.image,
                () => _changeCoverImage(context),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Privacy Settings
          _buildSettingsSection(
            context,
            'Privacy Settings',
            [
              _buildSettingTile(
                context,
                'Visibility',
                community.visibility.toUpperCase(),
                Icons.visibility,
                () => _changeVisibility(context),
              ),
              _buildSettingTile(
                context,
                'Approval Required',
                community.approvalRequired ? 'Yes' : 'No',
                Icons.approval,
                () => _toggleApproval(context),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Danger Zone
          _buildSettingsSection(
            context,
            'Danger Zone',
            [
              _buildSettingTile(
                context,
                'Delete Community',
                'Permanently delete this community',
                Icons.delete_forever,
                () => _deleteCommunity(context),
                isDanger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.neutralWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.onSurfaceColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? AppTheme.errorColor : AppTheme.primaryBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppTheme.errorColor : AppTheme.onSurfaceColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDanger ? AppTheme.errorColor.withOpacity(0.7) : AppTheme.onSurfaceColor.withOpacity(0.7),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildNotificationSetting(
    BuildContext context,
    WidgetRef ref,
    String key,
    String title,
    String subtitle,
    IconData icon,
    bool value,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          ref.read(notificationSettingsProvider.notifier).state = {
            ...ref.read(notificationSettingsProvider),
            key: newValue,
          };
        },
        activeColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildAnalyticsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> communityStatsAsync,
  ) {
    final advancedAnalyticsAsync = ref.watch(advancedAnalyticsProvider(community.id));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          
          // Basic stats
          communityStatsAsync.when(
            data: (stats) => _buildBasicAnalytics(context, stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading basic analytics')),
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Advanced analytics
          advancedAnalyticsAsync.when(
            data: (analytics) => _buildAdvancedAnalytics(context, analytics),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading advanced analytics')),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicAnalytics(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Metrics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.defaultPadding,
          mainAxisSpacing: AppConstants.defaultPadding,
          childAspectRatio: 1.5,
          children: [
            _buildAnalyticsCard(
              context,
              'Total Revenue',
              '\$${stats['total_revenue'] ?? 0}',
              Icons.attach_money,
              AppTheme.primaryGreen,
            ),
            _buildAnalyticsCard(
              context,
              'This Month',
              '\$${stats['monthly_revenue'] ?? 0}',
              Icons.trending_up,
              AppTheme.primaryBlue,
            ),
            _buildAnalyticsCard(
              context,
              'Active Members',
              '${stats['active_members'] ?? 0}',
              Icons.people,
              AppTheme.primaryOrange,
            ),
            _buildAnalyticsCard(
              context,
              'Avg. Session',
              '${stats['avg_session_minutes'] ?? 0}m',
              Icons.timer,
              AppTheme.primaryPurple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedAnalytics(BuildContext context, Map<String, dynamic> analytics) {
    // Extract variables before the widget build
    final revenueMetrics = analytics['revenue_metrics'] as Map<String, dynamic>? ?? {};
    final contentDistribution = analytics['content_distribution'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Analytics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Engagement metrics
        _buildAnalyticsSection(
          context,
          'Engagement Metrics',
          [
            _buildAnalyticsCard(
              context,
              'Engagement Rate',
              '${((analytics['engagement_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
              AppTheme.primaryGreen,
            ),
            _buildAnalyticsCard(
              context,
              'Growth Rate',
              '${((analytics['growth_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.show_chart,
              AppTheme.primaryBlue,
            ),
            _buildAnalyticsCard(
              context,
              'Retention Rate',
              '${((analytics['retention_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.people_outline,
              AppTheme.primaryOrange,
            ),
            _buildAnalyticsCard(
              context,
              'Avg Response Time',
              '${analytics['avg_response_time'] ?? 0}h',
              Icons.schedule,
              AppTheme.primaryPurple,
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.largePadding),
        
        // Revenue metrics
        _buildAnalyticsSection(
          context,
          'Revenue Metrics',
          [
            _buildAnalyticsCard(
              context,
              'Total Revenue',
              '\$${(revenueMetrics['total_revenue'] ?? 0).toStringAsFixed(0)}',
              Icons.attach_money,
              AppTheme.primaryGreen,
            ),
            _buildAnalyticsCard(
              context,
              'Monthly Revenue',
              '\$${(revenueMetrics['monthly_revenue'] ?? 0).toStringAsFixed(0)}',
              Icons.trending_up,
              AppTheme.primaryBlue,
            ),
            _buildAnalyticsCard(
              context,
              'Avg Transaction',
              '\$${(revenueMetrics['avg_transaction'] ?? 0).toStringAsFixed(0)}',
              Icons.shopping_cart,
              AppTheme.primaryOrange,
            ),
            _buildAnalyticsCard(
              context,
              'Conversion Rate',
              '${((revenueMetrics['conversion_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.percent,
              AppTheme.primaryPurple,
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.largePadding),
        
        // Content distribution
        _buildAnalyticsSection(
          context,
          'Content Distribution',
          [
            _buildAnalyticsCard(
              context,
              'Messages',
              '${((contentDistribution['messages'] ?? 0) * 100).toStringAsFixed(0)}%',
              Icons.chat,
              AppTheme.primaryBlue,
            ),
            _buildAnalyticsCard(
              context,
              'Events',
              '${((contentDistribution['events'] ?? 0) * 100).toStringAsFixed(0)}%',
              Icons.event,
              AppTheme.primaryGreen,
            ),
            _buildAnalyticsCard(
              context,
              'Moments',
              '${((contentDistribution['moments'] ?? 0) * 100).toStringAsFixed(0)}%',
              Icons.flash_on,
              AppTheme.primaryOrange,
            ),
            _buildAnalyticsCard(
              context,
              'Polls',
              '${((contentDistribution['polls'] ?? 0) * 100).toStringAsFixed(0)}%',
              Icons.poll,
              AppTheme.primaryPurple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () {
                // TODO: Refresh analytics data
                NavigationService.showSnackBar(
                  message: 'Analytics refreshed!',
                  backgroundColor: AppTheme.primaryGreen,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.defaultPadding,
          mainAxisSpacing: AppConstants.defaultPadding,
          childAspectRatio: 1.5,
          children: children,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModerationTab(BuildContext context, WidgetRef ref, ValueNotifier<bool> isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Moderation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Moderation stats
          Row(
            children: [
              _buildModerationStat(
                context,
                'Reported Content',
                '3',
                AppTheme.primaryOrange,
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              _buildModerationStat(
                context,
                'Banned Users',
                '${community.bannedUsers.length}',
                AppTheme.errorColor,
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Moderation actions
          Expanded(
            child: ListView(
              children: [
                _buildModerationCard(
                  context,
                  'Reported Messages',
                  'Review and moderate reported messages',
                  Icons.report,
                  AppTheme.primaryOrange,
                  () => _reviewReportedMessages(context),
                ),
                _buildModerationCard(
                  context,
                  'Banned Users',
                  'Manage banned users and appeals',
                  Icons.block,
                  AppTheme.errorColor,
                  () => _manageBannedUsers(context),
                ),
                _buildModerationCard(
                  context,
                  'Content Filters',
                  'Configure automatic content filtering',
                  Icons.filter_list,
                  AppTheme.primaryBlue,
                  () => _configureContentFilters(context),
                ),
                _buildModerationCard(
                  context,
                  'Moderation Log',
                  'View moderation activity history',
                  Icons.history,
                  AppTheme.primaryGreen,
                  () => _viewModerationLog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationStat(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Action handlers
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Management Help'),
        content: const Text(
          'This screen allows you to manage your community settings, members, and content. '
          'Use the tabs to navigate between different management areas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _createEvent(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Event creation coming soon!',
    );
  }

  void _sendAnnouncement(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Announcement feature coming soon!',
    );
  }

  void _manageMembers(BuildContext context) {
    // Already in members tab
  }

  void _viewAnalytics(BuildContext context) {
    // Already in analytics tab
  }

  void _inviteMembers(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Members'),
        content: const Text('Choose how you want to invite members:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEmailInviteDialog(context);
            },
            child: const Text('Email Invite'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPhoneInviteDialog(context);
            },
            child: const Text('Phone Invite'),
          ),
        ],
      ),
    );
  }

  void _showEmailInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    final emails = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Email Invitations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter email addresses (one per line):'),
              const SizedBox(height: AppConstants.smallPadding),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (email) {
                  if (email.isNotEmpty && !emails.contains(email)) {
                    setState(() {
                      emails.add(email);
                      emailController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: AppConstants.smallPadding),
              if (emails.isNotEmpty) ...[
                const Text('Emails to invite:'),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.onSurfaceColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: emails.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(emails[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
                        onPressed: () {
                          setState(() {
                            emails.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: emails.isEmpty ? null : () {
                Navigator.pop(context);
                _sendBulkInvitations(context, emails);
              },
              child: const Text('Send Invitations'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoneInviteDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final phones = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Phone Invitations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter phone numbers (one per line):'),
              const SizedBox(height: AppConstants.smallPadding),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (phone) {
                  if (phone.isNotEmpty && !phones.contains(phone)) {
                    setState(() {
                      phones.add(phone);
                      phoneController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: AppConstants.smallPadding),
              if (phones.isNotEmpty) ...[
                const Text('Phones to invite:'),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.onSurfaceColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: phones.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(phones[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
                        onPressed: () {
                          setState(() {
                            phones.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: phones.isEmpty ? null : () {
                Navigator.pop(context);
                _sendBulkInvitations(context, phones);
              },
              child: const Text('Send Invitations'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendBulkInvitations(BuildContext context, List<String> contacts) {
    // TODO: Implement actual invitation sending
    NavigationService.showSnackBar(
      message: 'Invitations sent to ${contacts.length} contact(s)!',
      backgroundColor: AppTheme.primaryGreen,
    );
  }

  void _handleMemberAction(
    BuildContext context,
    WidgetRef ref,
    String memberId,
    String action,
    ValueNotifier<bool> isLoading,
  ) {
    switch (action) {
      case 'ban':
        _banUser(context, ref, memberId, isLoading);
        break;
      case 'remove':
        _removeUser(context, ref, memberId, isLoading);
        break;
    }
  }

  void _banSelectedMembers(BuildContext context, WidgetRef ref) {
    final selectedMembers = ref.read(selectedMembersProvider(community.id));
    if (selectedMembers.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban Selected Members'),
        content: Text('Are you sure you want to ban ${selectedMembers.length} member(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(bulkActionsProvider(community.id).notifier)
                  .banSelectedMembers(community.id, selectedMembers.toList());
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  void _removeSelectedMembers(BuildContext context, WidgetRef ref) {
    final selectedMembers = ref.read(selectedMembersProvider(community.id));
    if (selectedMembers.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Selected Members'),
        content: Text('Are you sure you want to remove ${selectedMembers.length} member(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(bulkActionsProvider(community.id).notifier)
                  .removeSelectedMembers(community.id, selectedMembers.toList());
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryOrange),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _banUser(BuildContext context, WidgetRef ref, String memberId, ValueNotifier<bool> isLoading) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: const Text('Are you sure you want to ban this user? They will no longer be able to access the community.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement ban user
              NavigationService.showSnackBar(
                message: 'User banned successfully',
                backgroundColor: AppTheme.primaryGreen,
              );
            },
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  void _removeUser(BuildContext context, WidgetRef ref, String memberId, ValueNotifier<bool> isLoading) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: const Text('Are you sure you want to remove this user from the community?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement remove user
              NavigationService.showSnackBar(
                message: 'User removed successfully',
                backgroundColor: AppTheme.primaryGreen,
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _editCommunityName(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Edit community name coming soon!',
    );
  }

  void _editDescription(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Edit description coming soon!',
    );
  }

  void _changeCoverImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Cover Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how you want to update the cover image:'),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromGallery(context);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _takePhoto(context);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            if (community.coverImage.isNotEmpty) ...[
              const Text('Current cover image:'),
              const SizedBox(height: AppConstants.smallPadding),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.onSurfaceColor.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    community.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.neutralLightGray,
                      child: const Icon(Icons.image, size: 40),
                    ),
                  ),
                ),
              ),
            ],
          ],
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

  void _pickImageFromGallery(BuildContext context) {
    // TODO: Implement image picker from gallery
    NavigationService.showSnackBar(
      message: 'Image picker from gallery coming soon!',
    );
  }

  void _takePhoto(BuildContext context) {
    // TODO: Implement camera functionality
    NavigationService.showSnackBar(
      message: 'Camera functionality coming soon!',
    );
  }

  void _changeVisibility(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Change visibility coming soon!',
    );
  }

  void _toggleApproval(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Toggle approval coming soon!',
    );
  }

  void _deleteCommunity(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Community'),
        content: const Text(
          'Are you sure you want to delete this community? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete community
              NavigationService.showSnackBar(
                message: 'Community deleted successfully',
                backgroundColor: AppTheme.primaryGreen,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _reviewReportedMessages(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Reported messages review coming soon!',
    );
  }

  void _manageBannedUsers(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Banned users management coming soon!',
    );
  }

  void _configureContentFilters(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Content filters configuration coming soon!',
    );
  }

  void _viewModerationLog(BuildContext context) {
    NavigationService.showSnackBar(
      message: 'Moderation log coming soon!',
    );
  }
} 