import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/navigation_service.dart';
import '../core/logger.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import 'community_details_screen_dialogs.dart';

class CommunityDetailsLogic {
  static int getTabCount(AsyncValue<String> membershipAsync) {
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

  static void handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String value,
    CommunityModel community,
  ) {
    switch (value) {
      case 'share':
        _shareCommunity(context, community);
        break;
      case 'edit':
        _editCommunity(context, community);
        break;
      case 'delete':
        CommunityDetailsDialogs.showDeleteCommunityDialog(context, ref, community);
        break;
      case 'leave':
        CommunityDetailsDialogs.showLeaveCommunityDialog(context, ref, community);
        break;
      case 'report':
        _reportCommunity(context, community);
        break;
    }
  }

  static List<PopupMenuEntry<String>> buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    final membershipAsync = ref.watch(communityMembershipProvider(community.id));
    
    return membershipAsync.when(
      data: (membership) {
        final items = <PopupMenuEntry<String>>[];
        
        // Share option for all users
        items.add(
          PopupMenuItem(
            value: 'share',
            child: const ListTile(
              leading: Icon(Icons.share_outlined),
              title: Text('Share Community'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
        
        // Admin-only options
        if (membership == 'admin') {
          items.add(
            PopupMenuItem(
              value: 'edit',
              child: const ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit Community'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
          items.add(
            PopupMenuItem(
              value: 'delete',
              child: const ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete Community', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
        } else {
          // Member options
          items.add(
            PopupMenuItem(
              value: 'leave',
              child: const ListTile(
                leading: Icon(Icons.exit_to_app_outlined),
                title: Text('Leave Community'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
        }
        
        // Report option for non-admins
        if (membership != 'admin') {
          items.add(
            PopupMenuItem(
              value: 'report',
              child: const ListTile(
                leading: Icon(Icons.report_outlined),
                title: Text('Report Community'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          );
        }
        
        return items;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  static void handleJoinRequest(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    final userAsync = ref.watch(authNotifierProvider);
    
    userAsync.when(
      data: (user) {
        if (user == null) {
          CommunityDetailsDialogs.showSignInRequiredDialog(context);
          return;
        }
        
        CommunityDetailsDialogs.showJoinCommunityDialog(context, ref, community);
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  static void handleLeaveCommunity(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    // TODO: Implement leave community logic
    Logger('CommunityDetailsLogic').d('Leaving community: ${community.id}');
  }

  static void handleCreateEvent(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    // TODO: Navigate to create event screen
    Logger('CommunityDetailsLogic').d('Creating event for community: ${community.id}');
    NavigationService.navigateToCreateEvent(communityId: community.id);
  }

  static void handleMemberOptions(
    BuildContext context,
    WidgetRef ref,
    UserModel member,
    CommunityModel community,
  ) {
    CommunityDetailsDialogs.showMemberOptionsDialog(context, ref, member, community);
  }

  static void handleMemberManagement(
    BuildContext context,
    CommunityModel community,
  ) {
    CommunityDetailsDialogs.showMemberManagementDialog(context, community);
  }

  static void handleCommunitySettings(
    BuildContext context,
    CommunityModel community,
  ) {
    CommunityDetailsDialogs.showCommunitySettingsDialog(context, community);
  }

  static void handleAnalytics(
    BuildContext context,
    CommunityModel community,
  ) {
    CommunityDetailsDialogs.showAnalyticsDialog(context, community);
  }

  static void handleModeration(
    BuildContext context,
    CommunityModel community,
  ) {
    CommunityDetailsDialogs.showModerationDialog(context, community);
  }

  static void handleJoinRequestsReview(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    CommunityDetailsDialogs.showJoinRequestsReviewDialog(context, ref, community);
  }

  static void _shareCommunity(BuildContext context, CommunityModel community) {
    // TODO: Implement share functionality
    Logger('CommunityDetailsLogic').d('Sharing community: ${community.id}');
  }

  static void _editCommunity(BuildContext context, CommunityModel community) {
    // TODO: Navigate to edit community screen
    Logger('CommunityDetailsLogic').d('Editing community: ${community.id}');
  }

  static void _reportCommunity(BuildContext context, CommunityModel community) {
    // TODO: Implement report functionality
    Logger('CommunityDetailsLogic').d('Reporting community: ${community.id}');
  }

  static String formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  static List<UserModel> filterMembers(
    List<UserModel> members,
    String searchQuery,
    String selectedFilter,
  ) {
    List<UserModel> filteredMembers = members;
    
    // Search filter
    if (searchQuery.isNotEmpty) {
      filteredMembers = members.where((member) =>
        member.displayName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false
      ).toList();
    }
    
    // Role filter
    if (selectedFilter == 'admin') {
      // Note: This would need community.adminUid to be passed in
      // For now, we'll just return the filtered list
      return filteredMembers;
    } else if (selectedFilter == 'recent') {
      // Show members who joined in last 7 days
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      filteredMembers = filteredMembers.where((member) =>
        member.createdAt.isAfter(weekAgo)
      ).toList();
    }
    
    return filteredMembers;
  }

  static bool isCurrentUser(UserModel? currentUser, UserModel member) {
    return currentUser?.id == member.id;
  }

  static bool isAdmin(UserModel member, CommunityModel community) {
    return member.id == community.adminUid;
  }

  static bool isGuest(UserModel? user) {
    return user == null || user.role == 'anonymous';
  }

  static bool canCreateEvents(String membership) {
    return membership == 'admin' || membership == 'member';
  }

  static bool canManageMembers(String membership) {
    return membership == 'admin';
  }

  static bool canViewAdminTab(String membership) {
    return membership == 'admin';
  }
} 