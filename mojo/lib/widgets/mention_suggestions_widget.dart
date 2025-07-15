import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_model.dart';
import '../services/mention_service.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';

class MentionSuggestionsWidget extends ConsumerWidget {
  final String text;
  final int cursorPosition;
  final List<UserModel> communityMembers;
  final Function(UserModel) onUserSelected;
  final VoidCallback onDismiss;

  const MentionSuggestionsWidget({
    super.key,
    required this.text,
    required this.cursorPosition,
    required this.communityMembers,
    required this.onUserSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionService = ref.watch(mentionServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Check if we should show suggestions
    if (!mentionService.shouldShowMentionSuggestions(text, cursorPosition)) {
      return const SizedBox.shrink();
    }

    // Get the current mention query
    final query = mentionService.getMentionQuery(text, cursorPosition);
    
    // Filter members based on query
    final currentUser = ref.watch(authNotifierProvider).value;
    final filteredMembers = mentionService.filterMembersForMention(
      communityMembers,
      query,
      currentUser?.id ?? '',
    );

    if (filteredMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.alternate_email,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mention someone',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Suggestions list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final user = filteredMembers[index];
                final isSelected = index == 0; // First item is selected by default
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onUserSelected(user),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: AppConstants.smallPadding,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // User avatar
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                            backgroundImage: user.profilePictureUrl?.isNotEmpty == true
                                ? NetworkImage(user.profilePictureUrl!)
                                : null,
                            child: user.profilePictureUrl?.isEmpty != false
                                ? Text(
                                    user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? 'Unknown User',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (user.email?.isNotEmpty == true) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Online indicator
                          if (user.isOnline) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 