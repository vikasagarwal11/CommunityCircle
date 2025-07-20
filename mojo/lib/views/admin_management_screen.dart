import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/community_providers.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';

// Import modularized tabs
import 'admin_management_screen_overview_tab.dart';
import 'admin_management_screen_members_tab.dart';
import 'admin_management_screen_settings_tab.dart';
import 'admin_management_screen_analytics_tab.dart';
import 'admin_management_screen_moderation_tab.dart';

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
        backgroundColor: Theme.of(context).colorScheme.background,
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
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${community.members.length} members',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        community.visibility.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: community.visibility == 'public'
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.tertiary,
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
        color: Theme.of(context).colorScheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
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
        return AdminManagementOverviewTab(
          community: community,
          communityStatsAsync: communityStatsAsync,
        );
      case 1:
        return AdminManagementMembersTab(
          community: community,
          isLoading: isLoading,
        );
      case 2:
        return AdminManagementSettingsTab(
          community: community,
          isLoading: isLoading,
        );
      case 3:
        return AdminManagementAnalyticsTab(
          community: community,
          communityStatsAsync: communityStatsAsync,
        );
      case 4:
        return AdminManagementModerationTab(
          community: community,
          isLoading: isLoading,
        );
      default:
        return const Center(child: Text('Tab not found'));
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Management Help'),
        content: const Text(
          'Use the tabs to manage different aspects of your community:\n\n'
          '• Overview: Quick stats and actions\n'
          '• Members: Manage community members\n'
          '• Settings: Configure community settings\n'
          '• Analytics: View community metrics\n'
          '• Moderation: Handle reports and content',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
} 