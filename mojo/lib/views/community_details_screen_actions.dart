import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../core/navigation_service.dart';
import 'community_details_screen_logic.dart';

Widget? buildCommunityDetailsFAB(
  BuildContext context,
  WidgetRef ref,
  CommunityModel community,
  AsyncValue<String> membershipAsync,
) {
  return membershipAsync.when(
    data: (membership) {
      if (membership == 'none') {
        return FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).colorScheme.background,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: buildJoinCommunitySheet(context, ref, community),
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.secondary,
          icon: Icon(
            community.hasJoinQuestions ? Icons.question_answer : Icons.add,
            color: Colors.white,
          ),
          label: const Text('Join', style: TextStyle(color: Colors.white)),
        );
      }
      return FloatingActionButton(
        heroTag: 'community_details_fab',
        onPressed: () => showActionSheet(context, ref, community, membership),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
}

Widget buildJoinCommunitySheet(BuildContext context, WidgetRef ref, CommunityModel community) {
  return Container(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.group_add_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Join Community',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Join ${community.name}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              joinCommunity(context, ref, community);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              community.hasJoinQuestions ? 'Join & Answer Questions' : 'Join Community',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      ],
    ),
  );
}

void showActionSheet(BuildContext context, WidgetRef ref, CommunityModel community, String membership) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          buildActionItem(
            context,
            'Create Event',
            'Schedule a new community event',
            Icons.event_rounded,
            () {
              Navigator.pop(context);
              createEvent(context, ref, community);
            },
          ),
          if (membership == 'admin')
            buildActionItem(
              context,
              'Invite Members',
              'Send invitations to join',
              Icons.person_add_rounded,
              () {
                Navigator.pop(context);
                inviteMembers(context, ref, community);
              },
            ),
          buildActionItem(
            context,
            'Share Community',
            'Share with friends',
            Icons.share_rounded,
            () {
              Navigator.pop(context);
              shareCommunity(context, community);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildActionItem(
  BuildContext context,
  String title,
  String subtitle,
  IconData icon,
  VoidCallback onTap,
) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
    ),
    title: Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    ),
    onTap: onTap,
  );
}

void joinCommunity(BuildContext context, WidgetRef ref, CommunityModel community) {
  // TODO: Implement join community logic
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Joining ${community.name}...'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
  );
}

void createEvent(BuildContext context, WidgetRef ref, CommunityModel community) {
  // Use centralized logic for event creation
  CommunityDetailsLogic.handleCreateEvent(context, ref, community);
}

void inviteMembers(BuildContext context, WidgetRef ref, CommunityModel community) {
  // TODO: Implement invite members functionality
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Invite functionality coming soon!'),
      backgroundColor: Colors.blue,
    ),
  );
}

void shareCommunity(BuildContext context, CommunityModel community) {
  // TODO: Implement share functionality
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Sharing ${community.name}'),
      backgroundColor: Theme.of(context).colorScheme.secondary,
    ),
  );
} 