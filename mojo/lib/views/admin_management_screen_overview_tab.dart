import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import 'community_details_screen_logic.dart';

class AdminManagementOverviewTab extends ConsumerWidget {
  final CommunityModel community;
  final AsyncValue<Map<String, dynamic>> communityStatsAsync;

  const AdminManagementOverviewTab({
    super.key,
    required this.community,
    required this.communityStatsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          _buildQuickStats(context),
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

  Widget _buildQuickStats(BuildContext context) {
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
                Theme.of(context).colorScheme.primary,
              ),
              _buildStatCard(
                context,
                'Events',
                '${stats['recent_events'] ?? 0}',
                Icons.event,
                Theme.of(context).colorScheme.secondary,
              ),
              _buildStatCard(
                context,
                'Messages',
                '${stats['recent_messages'] ?? 0}',
                Icons.chat,
                Theme.of(context).colorScheme.tertiary,
              ),
              _buildStatCard(
                context,
                'Active',
                '${stats['active_members'] ?? 0}',
                Icons.trending_up,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 32,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Unable to load stats',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Check your connection and try again',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                // Fallback stats using community data
                GridView.count(
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
                      '${community.members.length}',
                      Icons.people,
                      Theme.of(context).colorScheme.primary,
                    ),
                    _buildStatCard(
                      context,
                      'Type',
                      community.isBusiness ? 'Business' : 'Social',
                      Icons.business,
                      Theme.of(context).colorScheme.secondary,
                    ),
                    _buildStatCard(
                      context,
                      'Visibility',
                      community.visibility,
                      Icons.visibility,
                      Theme.of(context).colorScheme.tertiary,
                    ),
                    _buildStatCard(
                      context,
                      'Created',
                      _formatDate(community.createdAt),
                      Icons.calendar_today,
                      Theme.of(context).colorScheme.primary,
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                Icons.person_add,
                'New member joined',
                '2 hours ago',
                Colors.green,
              ),
              _buildActivityItem(
                context,
                Icons.event,
                'Event created',
                '1 day ago',
                Colors.blue,
              ),
              _buildActivityItem(
                context,
                Icons.chat,
                'New message',
                '3 hours ago',
                Colors.orange,
              ),
              _buildActivityItem(
                context,
                Icons.photo,
                'Photo shared',
                '5 hours ago',
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    IconData icon,
    String title,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.defaultPadding),
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
          childAspectRatio: 1.8,
          children: [
            _buildActionCard(
              context,
              'Invite Members',
              Icons.person_add,
              Colors.green,
              () => _inviteMembers(context),
            ),
            _buildActionCard(
              context,
              'Create Event',
              Icons.event,
              Colors.blue,
              () => _createEvent(context),
            ),
            _buildActionCard(
              context,
              'Send Message',
              Icons.message,
              Colors.orange,
              () => _sendMessage(context),
            ),
            _buildActionCard(
              context,
              'View Analytics',
              Icons.analytics,
              Colors.purple,
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _inviteMembers(BuildContext context) {
    // TODO: Implement invite members functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite members functionality coming soon!')),
    );
  }

  void _createEvent(BuildContext context) {
    // Use centralized logic for event creation
    // Since this is a ConsumerWidget, we need to pass ref differently
    // For now, let's use direct navigation
    NavigationService.navigateToCreateEvent(communityId: community.id);
  }

  void _sendMessage(BuildContext context) {
    // Show member selection dialog for messaging
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Message'),
        content: const Text('This feature will allow you to send messages to community members. Coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewAnalytics(BuildContext context) {
    // TODO: Implement view analytics functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View analytics functionality coming soon!')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 