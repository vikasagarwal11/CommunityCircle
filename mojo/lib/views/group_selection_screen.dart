import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../providers/group_chat_providers.dart';
import '../providers/user_providers.dart';
import '../models/user_model.dart';
import '../models/personal_message_model.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class GroupSelectionScreen extends HookConsumerWidget {
  final String otherUserId;
  final String otherUserName;

  const GroupSelectionScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final selectedGroup = useState<PersonalChatModel?>(null);
    
    final currentUserAsync = ref.watch(authNotifierProvider);
    final personalChatsAsync = ref.watch(personalChatsProvider);

    // Filter group chats (chats with more than 2 participants)
    final groupChats = useMemoized(() {
      if (personalChatsAsync.value == null) return <PersonalChatModel>[];
      
      final query = searchQuery.value.toLowerCase();
      return personalChatsAsync.value!.where((chat) {
        // Only show group chats (more than 2 participants)
        if (chat.participants.length <= 2) return false;
        
        // Filter by search query
        if (query.isNotEmpty) {
          return chat.groupName?.toLowerCase().contains(query) ?? false;
        }
        return true;
      }).toList();
    }, [personalChatsAsync, searchQuery.value]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${otherUserName} to Group'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          
          // Groups list
          Expanded(
            child: personalChatsAsync.when(
              data: (chats) {
                if (groupChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          searchQuery.value.isNotEmpty 
                              ? 'No groups found'
                              : 'No group chats available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (searchQuery.value.isNotEmpty) ...[
                          const SizedBox(height: AppConstants.smallPadding),
                          Text(
                            'Try a different search term',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: groupChats.length,
                  itemBuilder: (context, index) {
                    final group = groupChats[index];
                    final isSelected = selectedGroup.value?.id == group.id;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: AppConstants.smallPadding,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            group.groupName?.substring(0, 1).toUpperCase() ?? 'G',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          group.groupName ?? 'Group Chat',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${group.participants.length} members',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        trailing: Radio<PersonalChatModel>(
                          value: group,
                          groupValue: selectedGroup.value,
                          onChanged: (value) {
                            selectedGroup.value = value;
                          },
                        ),
                        onTap: () {
                          selectedGroup.value = group;
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => CustomErrorWidget(
                message: 'Error loading groups: $error',
              ),
            ),
          ),
          
          // Add button
          if (selectedGroup.value != null)
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _addToGroup(context, ref, selectedGroup.value!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add ${otherUserName} to ${selectedGroup.value!.groupName ?? 'Group'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addToGroup(BuildContext context, WidgetRef ref, PersonalChatModel group) async {
    try {
      // Add the other user to the group
      await ref.read(groupChatStateProvider.notifier).addParticipantsToGroup(
        chatId: group.id,
        newParticipants: [otherUserId],
      );
      
      NavigationService.goBack();
      NavigationService.showSnackBar(
        message: '${otherUserName} added to ${group.groupName ?? 'group'} successfully!',
      );
    } catch (e) {
      NavigationService.showSnackBar(
        message: 'Failed to add user to group: $e',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }
} 