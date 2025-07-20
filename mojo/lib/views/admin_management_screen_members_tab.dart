import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/community_providers.dart';
import '../core/constants.dart';

class AdminManagementMembersTab extends HookConsumerWidget {
  final CommunityModel community;
  final ValueNotifier<bool> isLoading;

  const AdminManagementMembersTab({
    super.key,
    required this.community,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final selectedMembers = useState<Set<String>>({});
    final showBulkActions = useState(false);
    final filterRole = useState('all');
    
    final membersAsync = ref.watch(communityMembersProvider(community.id));

    return Column(
      children: [
        // Search and filter bar
        _buildSearchAndFilterBar(
          context,
          searchQuery,
          filterRole,
          showBulkActions,
          selectedMembers,
        ),
        
        // Bulk actions
        if (showBulkActions.value) ...[
          _buildBulkActions(context, selectedMembers, isLoading),
        ],
        
        // Members list
        Expanded(
          child: membersAsync.when(
            data: (members) => _buildMembersList(
              context,
              members,
              searchQuery.value,
              filterRole.value,
              selectedMembers,
              showBulkActions,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Failed to load members',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Please try again later',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar(
    BuildContext context,
    ValueNotifier<String> searchQuery,
    ValueNotifier<String> filterRole,
    ValueNotifier<bool> showBulkActions,
    ValueNotifier<Set<String>> selectedMembers,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
            ),
            onChanged: (value) {
              searchQuery.value = value;
              selectedMembers.value = {};
              showBulkActions.value = false;
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'All', 'all', filterRole),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Admins', 'admin', filterRole),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Moderators', 'moderator', filterRole),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Members', 'member', filterRole),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Inactive', 'inactive', filterRole),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    ValueNotifier<String> filterRole,
  ) {
    final isSelected = filterRole.value == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        filterRole.value = value;
      },
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildBulkActions(
    BuildContext context,
    ValueNotifier<Set<String>> selectedMembers,
    ValueNotifier<bool> isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${selectedMembers.value.length} selected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: isLoading.value ? null : () => _bulkMessage(context, selectedMembers),
            icon: const Icon(Icons.message),
            label: const Text('Message'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: isLoading.value ? null : () => _bulkPromote(context, selectedMembers),
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Promote'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: isLoading.value ? null : () => _bulkRemove(context, selectedMembers),
            icon: const Icon(Icons.remove_circle),
            label: const Text('Remove'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    List<UserModel> members,
    String searchQuery,
    String filterRole,
    ValueNotifier<Set<String>> selectedMembers,
    ValueNotifier<bool> showBulkActions,
  ) {
    final filteredMembers = members.where((member) {
      // Search filter
      final matchesSearch = member.displayName?.toLowerCase().contains(searchQuery.toLowerCase()) == true ||
                           member.email?.toLowerCase().contains(searchQuery.toLowerCase()) == true;
      
      // Role filter
      final matchesRole = filterRole == 'all' || 
                         (filterRole == 'admin' && member.isAdmin) ||
                         (filterRole == 'moderator' && member.role == 'moderator') ||
                         (filterRole == 'member' && member.role == 'member') ||
                         (filterRole == 'inactive' && !member.isOnline);
      
      return matchesSearch && matchesRole;
    }).toList();

    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No members found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        final isSelected = selectedMembers.value.contains(member.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                final newSelection = Set<String>.from(selectedMembers.value);
                if (value == true) {
                  newSelection.add(member.id);
                } else {
                  newSelection.remove(member.id);
                }
                selectedMembers.value = newSelection;
                showBulkActions.value = newSelection.isNotEmpty;
              },
            ),
            title: Text(member.displayName ?? 'Unknown User'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email ?? 'No email'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildRoleChip(context, member.role),
                    const SizedBox(width: 8),
                    if (member.isOnline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleMemberAction(context, action, member),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Profile')),
                const PopupMenuItem(value: 'message', child: Text('Send Message')),
                const PopupMenuItem(value: 'promote', child: Text('Promote')),
                const PopupMenuItem(value: 'demote', child: Text('Demote')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
            onTap: () {
              final newSelection = Set<String>.from(selectedMembers.value);
              if (isSelected) {
                newSelection.remove(member.id);
              } else {
                newSelection.add(member.id);
              }
              selectedMembers.value = newSelection;
              showBulkActions.value = newSelection.isNotEmpty;
            },
          ),
        );
      },
    );
  }

  Widget _buildRoleChip(BuildContext context, String role) {
    Color color;
    String label;

    switch (role) {
      case 'admin':
        color = Colors.red;
        label = 'Admin';
        break;
      case 'moderator':
        color = Colors.orange;
        label = 'Moderator';
        break;
      case 'member':
        color = Colors.blue;
        label = 'Member';
        break;
      default:
        color = Colors.grey;
        label = role;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleMemberAction(BuildContext context, String action, UserModel member) {
    switch (action) {
      case 'view':
        // TODO: Navigate to user profile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View ${member.displayName}\'s profile')),
        );
        break;
      case 'message':
        // TODO: Open chat with user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message ${member.displayName}')),
        );
        break;
      case 'promote':
        // TODO: Promote user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promote ${member.displayName}')),
        );
        break;
      case 'demote':
        // TODO: Demote user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demote ${member.displayName}')),
        );
        break;
      case 'remove':
        // TODO: Remove user from community
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remove ${member.displayName}')),
        );
        break;
    }
  }

  void _bulkMessage(BuildContext context, ValueNotifier<Set<String>> selectedMembers) {
    // TODO: Implement bulk messaging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message ${selectedMembers.value.length} members')),
    );
  }

  void _bulkPromote(BuildContext context, ValueNotifier<Set<String>> selectedMembers) {
    // TODO: Implement bulk promotion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Promote ${selectedMembers.value.length} members')),
    );
  }

  void _bulkRemove(BuildContext context, ValueNotifier<Set<String>> selectedMembers) {
    // TODO: Implement bulk removal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Remove ${selectedMembers.value.length} members')),
    );
  }
} 