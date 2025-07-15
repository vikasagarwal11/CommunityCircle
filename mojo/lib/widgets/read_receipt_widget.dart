import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';

class ReadReceiptWidget extends ConsumerWidget {
  final MessageModel message;
  final List<UserModel> communityMembers;
  final bool showDetailedReceipts;

  const ReadReceiptWidget({
    super.key,
    required this.message,
    required this.communityMembers,
    this.showDetailedReceipts = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUser = ref.watch(authNotifierProvider).value;
    
    if (!message.hasReadReceipts) return const SizedBox.shrink();

    // Get users who have read the message
    final readByUsers = communityMembers
        .where((user) => message.readBy.contains(user.id))
        .toList();

    // Get users who haven't read the message
    final unreadByUsers = communityMembers
        .where((user) => !message.readBy.contains(user.id) && user.id != message.userId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Read receipts
        if (showDetailedReceipts && readByUsers.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Read by avatars
                ...readByUsers.take(3).map((user) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 8,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
                
                if (readByUsers.length > 3) ...[
                  const SizedBox(width: 4),
                  Text(
                    '+${readByUsers.length - 3}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all,
                  size: 12,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ] else if (readByUsers.isNotEmpty) ...[
          // Simple read receipt
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.done_all,
                size: 12,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 2),
              Text(
                '${readByUsers.length} read',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
        
        // Unread indicator (if any)
        if (unreadByUsers.isNotEmpty && showDetailedReceipts) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Unread by avatars
                ...unreadByUsers.take(3).map((user) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: colorScheme.error.withOpacity(0.1),
                    child: Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 8,
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
                
                if (unreadByUsers.length > 3) ...[
                  const SizedBox(width: 4),
                  Text(
                    '+${unreadByUsers.length - 3}',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.error.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                
                const SizedBox(width: 4),
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: colorScheme.error,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
} 