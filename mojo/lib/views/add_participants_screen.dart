import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/database_providers.dart';
import '../providers/group_chat_providers.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class AddParticipantsScreen extends HookConsumerWidget {
  final String chatId;
  final bool isConvertingToGroup;
  final String? currentGroupName;

  const AddParticipantsScreen({
    super.key,
    required this.chatId,
    this.isConvertingToGroup = false,
    this.currentGroupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUsers = useState<Set<String>>({});
    final searchQuery = useState('');
    final isSearching = useState(false);
    final searchResults = useState<List<UserModel>>([]);
    final groupNameController = useTextEditingController(
      text: currentGroupName ?? '',
    );
    final groupDescriptionController = useTextEditingController();

    final allUsersAsync = ref.watch(usersProvider);
    final groupChatStateAsync = ref.watch(groupChatStateProvider);

    // Filter users based on search query
    final filteredUsers = useMemoized(() {
      if (allUsersAsync.value == null) return <UserModel>[];
      
      final query = searchQuery.value.toLowerCase();
      return allUsersAsync.value!.where((user) {
        final displayName = user.displayName?.toLowerCase() ?? '';
        final email = user.email?.toLowerCase() ?? '';
        return displayName.contains(query) || email.contains(query);
      }).toList();
    }, [allUsersAsync, searchQuery.value]);

    return Scaffold(
      appBar: AppBar(
        title: Text(isConvertingToGroup ? 'Create Group Chat' : 'Add Participants'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          if (selectedUsers.value.isNotEmpty)
            TextButton(
              onPressed: () async {
                await _addParticipants(
                  context,
                  ref,
                  selectedUsers.value.toList(),
                  groupNameController.text.trim(),
                  groupDescriptionController.text.trim(),
                );
              },
              child: const Text('Add'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Group info section (only for converting to group)
          if (isConvertingToGroup) _buildGroupInfoSection(
            context,
            groupNameController,
            groupDescriptionController,
          ),
          
          // Search bar
          _buildSearchBar(context, searchQuery),
          
          // Selected users count
          if (selectedUsers.value.isNotEmpty)
            _buildSelectedUsersCount(context, selectedUsers.value.length),
          
          // Users list
          Expanded(
            child: allUsersAsync.when(
              data: (users) {
                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('No users found'),
                  );
                }
                
                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isSelected = selectedUsers.value.contains(user.id);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        backgroundImage: user.profilePictureUrl != null 
                            ? NetworkImage(user.profilePictureUrl!)
                            : null,
                        child: user.profilePictureUrl == null
                            ? Text(
                                user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(user.displayName ?? 'Unknown User'),
                      subtitle: Text(user.email ?? ''),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          if (value == true) {
                            selectedUsers.value = {...selectedUsers.value, user.id};
                          } else {
                            selectedUsers.value = selectedUsers.value.difference({user.id});
                          }
                        },
                      ),
                      onTap: () {
                        if (isSelected) {
                          selectedUsers.value = selectedUsers.value.difference({user.id});
                        } else {
                          selectedUsers.value = {...selectedUsers.value, user.id};
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (error, _) => CustomErrorWidget(
                message: 'Error loading users: $error',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfoSection(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController descriptionController,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              hintText: 'Enter group name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'Enter group description',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ValueNotifier<String> searchQuery) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: TextField(
        onChanged: (value) => searchQuery.value = value,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildSelectedUsersCount(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            '$count user${count == 1 ? '' : 's'} selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addParticipants(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedUserIds,
    String groupName,
    String groupDescription,
  ) async {
    try {
      if (isConvertingToGroup) {
        if (groupName.trim().isEmpty) {
          NavigationService.showSnackBar(
            message: 'Please enter a group name',
            backgroundColor: Theme.of(context).colorScheme.error,
          );
          return;
        }
        
        await ref.read(groupChatStateProvider.notifier).convertToGroupChat(
          chatId: chatId,
          groupName: groupName.trim(),
          groupDescription: groupDescription.trim(),
          newParticipants: selectedUserIds,
        );
        
        NavigationService.showSnackBar(
          message: 'Group chat created successfully!',
        );
      } else {
        await ref.read(groupChatStateProvider.notifier).addParticipantsToGroup(
          chatId: chatId,
          newParticipants: selectedUserIds,
        );
        
        NavigationService.showSnackBar(
          message: '${selectedUserIds.length} participant(s) added successfully!',
        );
      }
      
      NavigationService.goBack();
    } catch (e) {
      NavigationService.showSnackBar(
        message: 'Error: $e',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }
} 