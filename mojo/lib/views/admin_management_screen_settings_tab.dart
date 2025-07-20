import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../widgets/export_widget.dart';
import '../core/navigation_service.dart';

class AdminManagementSettingsTab extends HookConsumerWidget {
  final CommunityModel community;
  final ValueNotifier<bool> isLoading;

  const AdminManagementSettingsTab({
    super.key,
    required this.community,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAdvancedSettings = useState(false);
    final showDangerZone = useState(false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Community Information
          _buildCommunityInfo(context),
          const SizedBox(height: AppConstants.largePadding),
          
          // General Settings
          _buildGeneralSettings(context, ref),
          const SizedBox(height: AppConstants.largePadding),
          
          // Privacy Settings
          _buildPrivacySettings(context, ref),
          const SizedBox(height: AppConstants.largePadding),
          
          // Notification Settings
          _buildNotificationSettings(context, ref),
          const SizedBox(height: AppConstants.largePadding),
          
          // Advanced Settings
          _buildAdvancedSettings(context, ref, showAdvancedSettings),
          const SizedBox(height: AppConstants.largePadding),
          
          // Danger Zone
          _buildDangerZone(context, ref, showDangerZone),
        ],
      ),
    );
  }

  Widget _buildCommunityInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildInfoRow(context, 'Name', community.name),
            _buildInfoRow(context, 'Description', community.description),
            _buildInfoRow(context, 'Visibility', community.visibility),
            _buildInfoRow(context, 'Type', community.isBusiness ? 'Business' : 'Social'),
            _buildInfoRow(context, 'Created', _formatDate(community.createdAt)),
            _buildInfoRow(context, 'Members', '${community.members.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildSettingTile(
              context,
              'Edit Community Info',
              'Update name, description, and basic settings',
              Icons.edit,
              () => _editCommunityInfo(context),
            ),
            _buildSettingTile(
              context,
              'Change Cover Image',
              'Update community cover photo',
              Icons.image,
              () => _changeCoverImage(context),
            ),
            _buildSettingTile(
              context,
              'Manage Categories',
              'Add or remove community categories',
              Icons.category,
              () => _manageCategories(context),
            ),
            _buildSettingTile(
              context,
              'Community Rules',
              'Set and manage community guidelines',
              Icons.rule,
              () => _manageRules(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildSwitchTile(
              context,
              'Public Community',
              'Anyone can find and join this community',
              Icons.public,
              community.visibility == 'public',
              (value) => _toggleVisibility(context, value),
            ),
            _buildSwitchTile(
              context,
              'Approval Required',
              'New members must be approved by admins',
              Icons.approval,
              community.approvalRequired,
              (value) => _toggleApproval(context, value),
            ),
            _buildSwitchTile(
              context,
              'Show Member List',
              'Members can see who else is in the community',
              Icons.people,
              true, // TODO: Get from community settings
              (value) => _toggleMemberListVisibility(context, value),
            ),
            _buildSwitchTile(
              context,
              'Allow Invites',
              'Members can invite others to join',
              Icons.person_add,
              true, // TODO: Get from community settings
              (value) => _toggleInvites(context, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildSwitchTile(
              context,
              'New Member Notifications',
              'Get notified when someone joins',
              Icons.person_add,
              true,
              (value) => _toggleNewMemberNotifications(context, value),
            ),
            _buildSwitchTile(
              context,
              'Event Notifications',
              'Get notified about new events',
              Icons.event,
              true,
              (value) => _toggleEventNotifications(context, value),
            ),
            _buildSwitchTile(
              context,
              'Message Notifications',
              'Get notified about new messages',
              Icons.message,
              true,
              (value) => _toggleMessageNotifications(context, value),
            ),
            _buildSwitchTile(
              context,
              'Weekly Digest',
              'Receive weekly community summary',
              Icons.summarize,
              false,
              (value) => _toggleWeeklyDigest(context, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> showAdvancedSettings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Advanced Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => showAdvancedSettings.value = !showAdvancedSettings.value,
                  icon: Icon(
                    showAdvancedSettings.value ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
            if (showAdvancedSettings.value) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _buildExportSection(context),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildSettingTile(
                context,
                'Backup Settings',
                'Create a backup of community settings',
                Icons.backup,
                () => _backupSettings(context),
              ),
              _buildSettingTile(
                context,
                'API Access',
                'Manage API keys and integrations',
                Icons.api,
                () => _manageApiAccess(context),
              ),
              _buildSettingTile(
                context,
                'Custom Domain',
                'Set up custom domain for community',
                Icons.domain,
                () => _setupCustomDomain(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> showDangerZone,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => showDangerZone.value = !showDangerZone.value,
                  icon: Icon(
                    showDangerZone.value ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            if (showDangerZone.value) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _buildDangerTile(
                context,
                'Transfer Ownership',
                'Transfer community ownership to another member',
                Icons.swap_horiz,
                () => _transferOwnership(context),
              ),
              _buildDangerTile(
                context,
                'Archive Community',
                'Archive this community (can be restored later)',
                Icons.archive,
                () => _archiveCommunity(context),
              ),
              _buildDangerTile(
                context,
                'Delete Community',
                'Permanently delete this community and all data',
                Icons.delete_forever,
                () => _deleteCommunity(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDangerTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.error),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7)),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Action methods
  void _editCommunityInfo(BuildContext context) {
    NavigationService.navigateToEditCommunity(community);
  }

  void _changeCoverImage(BuildContext context) {
    // TODO: Implement change cover image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change cover image functionality coming soon!')),
    );
  }

  void _manageCategories(BuildContext context) {
    // TODO: Implement manage categories
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manage categories functionality coming soon!')),
    );
  }

  void _manageRules(BuildContext context) {
    // TODO: Implement manage rules
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manage rules functionality coming soon!')),
    );
  }

  void _toggleVisibility(BuildContext context, bool value) {
    // TODO: Implement toggle visibility
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Community visibility: ${value ? 'Public' : 'Private'}')),
    );
  }

  void _toggleApproval(BuildContext context, bool value) {
    // TODO: Implement toggle approval
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approval required: ${value ? 'Yes' : 'No'}')),
    );
  }

  void _toggleMemberListVisibility(BuildContext context, bool value) {
    // TODO: Implement toggle member list visibility
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Show member list: ${value ? 'Yes' : 'No'}')),
    );
  }

  void _toggleInvites(BuildContext context, bool value) {
    // TODO: Implement toggle invites
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Allow invites: ${value ? 'Yes' : 'No'}')),
    );
  }

  void _toggleNewMemberNotifications(BuildContext context, bool value) {
    // TODO: Implement toggle new member notifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('New member notifications: ${value ? 'On' : 'Off'}')),
    );
  }

  void _toggleEventNotifications(BuildContext context, bool value) {
    // TODO: Implement toggle event notifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event notifications: ${value ? 'On' : 'Off'}')),
    );
  }

  void _toggleMessageNotifications(BuildContext context, bool value) {
    // TODO: Implement toggle message notifications
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message notifications: ${value ? 'On' : 'Off'}')),
    );
  }

  void _toggleWeeklyDigest(BuildContext context, bool value) {
    // TODO: Implement toggle weekly digest
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Weekly digest: ${value ? 'On' : 'Off'}')),
    );
  }

  void _exportData(BuildContext context) {
    // TODO: Implement export data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export data functionality coming soon!')),
    );
  }

  void _backupSettings(BuildContext context) {
    // TODO: Implement backup settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup settings functionality coming soon!')),
    );
  }

  void _manageApiAccess(BuildContext context) {
    // TODO: Implement manage API access
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manage API access functionality coming soon!')),
    );
  }

  void _setupCustomDomain(BuildContext context) {
    // TODO: Implement setup custom domain
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setup custom domain functionality coming soon!')),
    );
  }

  void _transferOwnership(BuildContext context) {
    // TODO: Implement transfer ownership
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer ownership functionality coming soon!')),
    );
  }

  void _archiveCommunity(BuildContext context) {
    // TODO: Implement archive community
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Archive community functionality coming soon!')),
    );
  }

  void _deleteCommunity(BuildContext context) {
    // TODO: Implement delete community
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete community functionality coming soon!')),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Data',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Download community data in various formats',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        CommunityAnalyticsExportWidget(
          community: community,
          analytics: {
            'member_count': community.members.length,
            'member_growth': '+12%',
            'active_members': (community.members.length * 0.8).round(),
            'active_growth': '+8%',
            'events_created': 5,
            'events_growth': '+15%',
            'messages_sent': 150,
            'messages_growth': '+23%',
            'engagement_rate': 85,
            'engagement_change': '+5%',
          },
        ),
        const SizedBox(height: AppConstants.smallPadding),
        MemberListExportWidget(
          community: community,
          members: community.members.map((memberId) => UserModel(
            id: memberId,
            phoneNumber: '+1234567890',
            displayName: 'Member $memberId',
            email: 'member$memberId@example.com',
            role: 'member',
            createdAt: DateTime.now(),
            lastSeen: DateTime.now(),
            isOnline: true,
          )).toList(),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 