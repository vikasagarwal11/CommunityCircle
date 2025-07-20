import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../core/constants.dart';
import 'community_details_screen_widgets.dart';
import 'community_details_screen_logic.dart';

class AdminTab extends HookConsumerWidget {
  final CommunityModel community;
  
  const AdminTab({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState('overview'); // 'overview', 'analytics', 'moderation', 'settings'
    final selectedTimeRange = useState('7d'); // '7d', '30d', '90d', '1y'
    
    return Column(
      children: [
        // Enhanced Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Admin Panel',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${community.members.length} members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tab Navigation
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildTabButton(context, 'Overview', 'overview', selectedTab.value, () {
                      selectedTab.value = 'overview';
                    }),
                    _buildTabButton(context, 'Analytics', 'analytics', selectedTab.value, () {
                      selectedTab.value = 'analytics';
                    }),
                    _buildTabButton(context, 'Moderation', 'moderation', selectedTab.value, () {
                      selectedTab.value = 'moderation';
                    }),
                    _buildTabButton(context, 'Settings', 'settings', selectedTab.value, () {
                      selectedTab.value = 'settings';
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: _buildTabContent(context, ref, selectedTab.value, selectedTimeRange.value),
        ),
      ],
    );
  }

  Widget _buildTabButton(BuildContext context, String label, String value, String selectedValue, VoidCallback onTap) {
    final isSelected = value == selectedValue;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected 
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref, String tab, String timeRange) {
    switch (tab) {
      case 'overview':
        return _buildOverviewTab(context, ref);
      case 'analytics':
        return _buildAnalyticsTab(context, ref, timeRange);
      case 'moderation':
        return _buildModerationTab(context, ref);
      case 'settings':
        return _buildSettingsTab(context, ref);
      default:
        return _buildOverviewTab(context, ref);
    }
  }

  Widget _buildOverviewTab(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Text(
            'Quick Stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CommunityDetailsWidgets.buildStatCard(
                  context,
                  'Total Members',
                  '${community.members.length}',
                  Icons.people_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommunityDetailsWidgets.buildStatCard(
                  context,
                  'Active Events',
                  '3',
                  Icons.event_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CommunityDetailsWidgets.buildStatCard(
                  context,
                  'New This Week',
                  '12',
                  Icons.trending_up_rounded,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommunityDetailsWidgets.buildStatCard(
                  context,
                  'Pending Requests',
                  '5',
                  Icons.pending_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildQuickActionCard(
                context,
                'Manage Members',
                Icons.people_outline_rounded,
                Colors.blue,
                () => CommunityDetailsLogic.handleMemberManagement(context, community),
              ),
              _buildQuickActionCard(
                context,
                'Create Event',
                Icons.add_rounded,
                Colors.green,
                () => CommunityDetailsLogic.handleCreateEvent(context, ref, community),
              ),
              _buildQuickActionCard(
                context,
                'Review Requests',
                Icons.pending_actions_rounded,
                Colors.orange,
                () => CommunityDetailsLogic.handleJoinRequestsReview(context, ref, community),
              ),
              _buildQuickActionCard(
                context,
                'Community Settings',
                Icons.settings_rounded,
                Colors.purple,
                () => CommunityDetailsLogic.handleCommunitySettings(context, community),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(context, 'New member joined', '2 minutes ago', Icons.person_add_rounded),
          _buildActivityItem(context, 'Event created', '1 hour ago', Icons.event_rounded),
          _buildActivityItem(context, 'Member reported', '3 hours ago', Icons.report_rounded),
          _buildActivityItem(context, 'Settings updated', '1 day ago', Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(BuildContext context, WidgetRef ref, String timeRange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Range Selector
          Row(
            children: [
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeRangeChip(context, '7D', '7d', timeRange),
                    _buildTimeRangeChip(context, '30D', '30d', timeRange),
                    _buildTimeRangeChip(context, '90D', '90d', timeRange),
                    _buildTimeRangeChip(context, '1Y', '1y', timeRange),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Growth Metrics
          Text(
            'Growth Metrics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Member Growth',
                  '+15%',
                  'vs last period',
                  Icons.trending_up_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Event Engagement',
                  '+23%',
                  'vs last period',
                  Icons.event_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Engagement Metrics
          Text(
            'Engagement Metrics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Active Members',
                  '78%',
                  'of total members',
                  Icons.people_rounded,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Event Attendance',
                  '85%',
                  'average attendance',
                  Icons.check_circle_rounded,
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Top Content
          Text(
            'Top Content',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTopContentItem(context, 'Weekly Community Meeting', '156 views', Icons.meeting_room_rounded),
          _buildTopContentItem(context, 'Workshop: Flutter Basics', '89 views', Icons.workspace_premium_rounded),
          _buildTopContentItem(context, 'Social Mixer Event', '67 views', Icons.people_rounded),
        ],
      ),
    );
  }

  Widget _buildModerationTab(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moderation Tools',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Moderation Stats
          Row(
            children: [
              Expanded(
                child: _buildModerationStatCard(
                  context,
                  'Reported Content',
                  '3',
                  Icons.report_rounded,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModerationStatCard(
                  context,
                  'Banned Users',
                  '1',
                  Icons.block_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Moderation Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildModerationActionCard(
            context,
            'Review Reported Content',
            '3 items need attention',
            Icons.report_rounded,
            () {},
          ),
          _buildModerationActionCard(
            context,
            'Manage Banned Users',
            '1 user currently banned',
            Icons.block_rounded,
            () {},
          ),
          _buildModerationActionCard(
            context,
            'Content Moderation',
            'Set up auto-moderation rules',
            Icons.shield_rounded,
            () {},
          ),
          _buildModerationActionCard(
            context,
            'Community Guidelines',
            'Edit community rules',
            Icons.rule_rounded,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // General Settings
          Text(
            'General',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            context,
            'Community Information',
            'Edit name, description, and privacy',
            Icons.info_rounded,
            () {},
          ),
          _buildSettingCard(
            context,
            'Privacy Settings',
            'Manage who can join and see content',
            Icons.privacy_tip_rounded,
            () {},
          ),
          _buildSettingCard(
            context,
            'Join Requirements',
            'Set up questions and approval process',
            Icons.question_answer_rounded,
            () {},
          ),
          
          const SizedBox(height: 16),
          
          // Advanced Settings
          Text(
            'Advanced',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            context,
            'Roles & Permissions',
            'Manage member roles and permissions',
            Icons.admin_panel_settings_rounded,
            () {},
          ),
          _buildSettingCard(
            context,
            'Integrations',
            'Connect with external services',
            Icons.integration_instructions_rounded,
            () {},
          ),
          _buildSettingCard(
            context,
            'Backup & Export',
            'Export community data',
            Icons.backup_rounded,
            () {},
          ),
          
          const SizedBox(height: 16),
          
          // Danger Zone
          Text(
            'Danger Zone',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          _buildDangerCard(
            context,
            'Delete Community',
            'Permanently delete this community',
            Icons.delete_forever_rounded,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(BuildContext context, String label, String value, String selectedValue) {
    final isSelected = value == selectedValue;
    
    return GestureDetector(
      onTap: () {
        // TODO: Update time range
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContentItem(BuildContext context, String title, String views, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            views,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModerationActionCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
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

  Widget _buildSettingCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
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

  Widget _buildDangerCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.error),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
        onTap: onTap,
      ),
    );
  }
} 