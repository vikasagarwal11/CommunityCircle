import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import 'community_details_screen_widgets.dart';
import 'community_details_screen_logic.dart';

class MembersTab extends HookConsumerWidget {
  final CommunityModel community;
  
  const MembersTab({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(authNotifierProvider);
    final searchQuery = ref.watch(memberSearchProvider(community.id));
    final debouncedQuery = ref.watch(debouncedSearchProvider(community.id));
    
    final selectedFilter = useState('all'); // 'all', 'admin', 'member', 'recent', 'active', 'inactive'
    final scrollController = useScrollController();
    final isRefreshing = useState(false);
    final isGridView = useState(true);
    final isSelectionMode = useState(false);
    final selectedMembers = useState<Set<String>>({});
    final showAdvancedFilters = useState(false);
    
    return Column(
      children: [
        // Enhanced Header with Bulk Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header with Actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Members',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // Bulk Actions Button
                  if (!isSelectionMode.value)
                    IconButton(
                      onPressed: () {
                        isSelectionMode.value = true;
                        selectedMembers.value = {};
                      },
                      icon: Icon(
                        Icons.select_all_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Select Members',
                    ),
                  
                  // View Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => isGridView.value = true,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isGridView.value 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: 16,
                              color: isGridView.value 
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => isGridView.value = false,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: !isGridView.value 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.view_list_rounded,
                              size: 16,
                              color: !isGridView.value 
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${community.members.length} members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              
              // Selection Mode Actions
              if (isSelectionMode.value) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedMembers.value.length} selected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          isSelectionMode.value = false;
                          selectedMembers.value = {};
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: selectedMembers.value.isEmpty ? null : () {
                          _showBulkActionsDialog(context, selectedMembers.value, community);
                        },
                        icon: const Icon(Icons.more_vert_rounded),
                        label: const Text('Actions'),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Enhanced Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: HookConsumer(
                  builder: (context, ref, child) {
                    final searchController = useTextEditingController();
                    final debounceTimer = useState<Timer?>(null);
                    
                    useEffect(() {
                      void updateSearch() {
                        final query = searchController.text;
                        ref.read(memberSearchProvider(community.id).notifier).state = query;
                        
                        debounceTimer.value?.cancel();
                        debounceTimer.value = Timer(const Duration(milliseconds: 200), () {
                          ref.read(debouncedSearchProvider(community.id).notifier).state = query;
                        });
                      }
                      
                      searchController.addListener(updateSearch);
                      return () {
                        searchController.removeListener(updateSearch);
                        debounceTimer.value?.cancel();
                      };
                    }, [searchController]);
                    
                    return TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search members...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  size: 20,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  ref.read(memberSearchProvider(community.id).notifier).state = '';
                                  ref.read(debouncedSearchProvider(community.id).notifier).state = '';
                                },
                              ),
                            IconButton(
                              icon: Icon(
                                showAdvancedFilters.value ? Icons.filter_list_rounded : Icons.filter_list_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              onPressed: () {
                                showAdvancedFilters.value = !showAdvancedFilters.value;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Advanced Filters
              if (showAdvancedFilters.value) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Filters',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(context, 'All', 'all', selectedFilter.value, () {
                            selectedFilter.value = 'all';
                          }),
                          _buildFilterChip(context, 'Admins', 'admin', selectedFilter.value, () {
                            selectedFilter.value = 'admin';
                          }),
                          _buildFilterChip(context, 'Recent', 'recent', selectedFilter.value, () {
                            selectedFilter.value = 'recent';
                          }),
                          _buildFilterChip(context, 'Active', 'active', selectedFilter.value, () {
                            selectedFilter.value = 'active';
                          }),
                          _buildFilterChip(context, 'Inactive', 'inactive', selectedFilter.value, () {
                            selectedFilter.value = 'inactive';
                          }),
                          _buildFilterChip(context, 'Online', 'online', selectedFilter.value, () {
                            selectedFilter.value = 'online';
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              // Search Results Indicator
              if (debouncedQuery.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Search results',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      ref.watch(communityMembersProvider(community.id)).when(
                        data: (members) {
                          final filteredCount = members.where((member) =>
                            member.displayName?.toLowerCase().contains(debouncedQuery.toLowerCase()) ?? false
                          ).length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$filteredCount found',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              
              // Quick Actions Bar
              if (!showAdvancedFilters.value)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(context, 'All', 'all', selectedFilter.value, () {
                        selectedFilter.value = 'all';
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'Admins', 'admin', selectedFilter.value, () {
                        selectedFilter.value = 'admin';
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'Recent', 'recent', selectedFilter.value, () {
                        selectedFilter.value = 'recent';
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, 'Online', 'online', selectedFilter.value, () {
                        selectedFilter.value = 'online';
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Members Grid/List with Selection
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              isRefreshing.value = true;
              await Future.delayed(const Duration(milliseconds: 800));
              ref.invalidate(communityMembersProvider(community.id));
              isRefreshing.value = false;
            },
            child: ref.watch(communityMembersProvider(community.id)).when(
              data: (members) {
                if (members.isEmpty) {
                  return CommunityDetailsWidgets.buildEmptyState(context, searchQuery);
                }
                
                // Apply filters
                List<UserModel> filteredMembers = members;
                
                // Search filter
                if (debouncedQuery.isNotEmpty) {
                  filteredMembers = members.where((member) =>
                    member.displayName?.toLowerCase().contains(debouncedQuery.toLowerCase()) ?? false
                  ).toList();
                }
                
                // Advanced filters
                filteredMembers = _applyAdvancedFilters(filteredMembers, selectedFilter.value, community);
                
                if (filteredMembers.isEmpty) {
                  return CommunityDetailsWidgets.buildEmptyState(context, debouncedQuery);
                }
                
                if (isGridView.value) {
                  return GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      final isCurrentUser = currentUserAsync.value?.id == member.id;
                      final isAdmin = member.id == community.adminUid;
                      final isSelected = selectedMembers.value.contains(member.id);
                      
                      return CommunityDetailsWidgets.buildCompactMemberCard(
                        context,
                        member,
                        isCurrentUser,
                        isAdmin,
                        community,
                        ref,
                        () => CommunityDetailsLogic.handleMemberOptions(context, ref, member, community),
                        isSelectionMode: isSelectionMode.value,
                        isSelected: isSelected,
                        onSelectionChanged: (selected) {
                          final newSelection = Set<String>.from(selectedMembers.value);
                          if (selected) {
                            newSelection.add(member.id);
                          } else {
                            newSelection.remove(member.id);
                          }
                          selectedMembers.value = newSelection;
                        },
                      );
                    },
                  );
                } else {
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      final isCurrentUser = currentUserAsync.value?.id == member.id;
                      final isAdmin = member.id == community.adminUid;
                      final isSelected = selectedMembers.value.contains(member.id);
                      
                      return CommunityDetailsWidgets.buildListMemberCard(
                        context,
                        member,
                        isCurrentUser,
                        isAdmin,
                        community,
                        ref,
                        () => CommunityDetailsLogic.handleMemberOptions(context, ref, member, community),
                        isSelectionMode: isSelectionMode.value,
                        isSelected: isSelected,
                        onSelectionChanged: (selected) {
                          final newSelection = Set<String>.from(selectedMembers.value);
                          if (selected) {
                            newSelection.add(member.id);
                          } else {
                            newSelection.remove(member.id);
                          }
                          selectedMembers.value = newSelection;
                        },
                      );
                    },
                  );
                }
              },
              loading: () => isGridView.value ? CommunityDetailsWidgets.buildSkeletonLoading() : CommunityDetailsWidgets.buildListSkeletonLoading(),
              error: (error, stack) => CommunityDetailsWidgets.buildErrorState(context, error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    String selectedValue,
    VoidCallback onTap,
  ) {
    return CommunityDetailsWidgets.buildFilterChip(context, label, value, selectedValue, onTap);
  }

  List<UserModel> _applyAdvancedFilters(List<UserModel> members, String filter, CommunityModel community) {
    switch (filter) {
      case 'admin':
        return members.where((member) => member.id == community.adminUid).toList();
      case 'recent':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return members.where((member) => member.createdAt.isAfter(weekAgo)).toList();
      case 'active':
        // Simulate active users (in real app, this would check activity data)
        return members.where((member) => member.createdAt.isAfter(
          DateTime.now().subtract(const Duration(days: 30))
        )).toList();
      case 'inactive':
        // Simulate inactive users
        return members.where((member) => member.createdAt.isBefore(
          DateTime.now().subtract(const Duration(days: 30))
        )).toList();
      case 'online':
        // Simulate online users (in real app, this would check online status)
        return members.take((members.length * 0.3).round()).toList();
      default:
        return members;
    }
  }

  void _showBulkActionsDialog(BuildContext context, Set<String> selectedMembers, CommunityModel community) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Bulk Actions (${selectedMembers.length} members)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.message_outlined),
              title: const Text('Send Message'),
              subtitle: const Text('Send a message to selected members'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement bulk messaging
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Promote to Admin'),
              subtitle: const Text('Give admin privileges'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement bulk promotion
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: const Text('Remove Members'),
              subtitle: const Text('Remove from community'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement bulk removal
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Ban Members'),
              subtitle: const Text('Ban from community'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement bulk banning
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 