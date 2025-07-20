import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/navigation_service.dart';
import '../widgets/join_questions_dialog.dart';

class CommunityDetailsDialogs {
  static void showSignInRequiredDialog(BuildContext context) {
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
  }

  static void showMemberOptionsDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel member,
    CommunityModel community,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.message_outlined),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToPersonalChat(member.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to member profile
              },
            ),
            if (member.id == community.adminUid)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin'),
                subtitle: const Text('Community administrator'),
                enabled: false,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void showJoinCommunityDialog(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    if (community.hasJoinQuestions) {
      showDialog(
        context: context,
        builder: (context) => JoinQuestionsDialog(
          questions: community.joinQuestions ?? [],
          onSubmit: (answers) {
            Navigator.pop(context);
            // TODO: Handle join with questions
          },
          onCancel: () {
            Navigator.pop(context);
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Join ${community.name}'),
          content: Text('Are you sure you want to join this community?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Handle join without questions
              },
              child: const Text('Join'),
            ),
          ],
        ),
      );
    }
  }

  static void showLeaveCommunityDialog(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${community.name}'),
        content: const Text('Are you sure you want to leave this community? You can rejoin later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle leave community
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  static void showDeleteCommunityDialog(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${community.name}'),
        content: const Text('This action cannot be undone. All members will be removed and all data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle delete community
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static void showCommunitySettingsDialog(
    BuildContext context,
    CommunityModel community,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Community'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToEditCommunity(community);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Community'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share community
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Invite Members'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Invite members
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void showMemberManagementDialog(
    BuildContext context,
    CommunityModel community,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Add Members'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add members
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: const Text('Remove Members'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Remove members
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Ban Members'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Ban members
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void showAnalyticsDialog(
    BuildContext context,
    CommunityModel community,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Member Growth'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show member growth analytics
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Event Analytics'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show event analytics
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up_outlined),
              title: const Text('Engagement Metrics'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show engagement metrics
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void showModerationDialog(
    BuildContext context,
    CommunityModel community,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Reported Content'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show reported content
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Moderation Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show moderation settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Banned Users'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show banned users
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void showJoinRequestsReviewDialog(
    BuildContext context,
    WidgetRef ref,
    CommunityModel community,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.pending_actions_outlined),
              title: const Text('Pending Requests'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to pending requests
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer_outlined),
              title: const Text('Review Answers'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to review answers
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 