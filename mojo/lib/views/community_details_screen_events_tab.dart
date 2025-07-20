import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../providers/community_providers.dart';
import '../providers/database_providers.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import 'community_details_screen_widgets.dart';
import 'community_details_screen_logic.dart';
import '../models/event_model.dart';

class EventsTab extends HookConsumerWidget {
  final CommunityModel community;
  
  const EventsTab({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = useState('all');
    final selectedFilter = useState('upcoming'); // 'upcoming', 'past', 'all'
    final searchQuery = useState('');
    final showTemplates = useState(false);
    final isGridView = useState(false); // Add view toggle state
    
    return Column(
      children: [
        // Enhanced Header with Actions
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
              // Header with Quick Actions
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
                          Icons.event_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Events',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // Template Button
                  IconButton(
                    onPressed: () => showTemplates.value = !showTemplates.value,
                    icon: Icon(
                      showTemplates.value ? Icons.dashboard_rounded : Icons.dashboard_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Event Templates',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Search and Filter Section
              Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) => searchQuery.value = value,
                        decoration: InputDecoration(
                          hintText: 'Search events...',
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
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // View Toggle Button
                  IconButton(
                    onPressed: () {
                      // Toggle between grid and list view
                      isGridView.value = !isGridView.value;
                    },
                    icon: Icon(
                      isGridView.value ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: isGridView.value ? 'List View' : 'Grid View',
                  ),
                  
                  // Templates Toggle Button
                  IconButton(
                    onPressed: () {
                      showTemplates.value = !showTemplates.value;
                    },
                    icon: Icon(
                      Icons.dashboard_rounded,
                      color: showTemplates.value 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    tooltip: 'Event Templates',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Event Templates
              if (showTemplates.value) ...[
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
                        'Event Templates',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTemplateCard(context, 'Meeting', Icons.meeting_room_rounded, 'Regular community meeting'),
                            const SizedBox(width: 8),
                            _buildTemplateCard(context, 'Workshop', Icons.workspace_premium_rounded, 'Educational workshop'),
                            const SizedBox(width: 8),
                            _buildTemplateCard(context, 'Social', Icons.people_rounded, 'Social gathering'),
                            const SizedBox(width: 8),
                            _buildTemplateCard(context, 'Webinar', Icons.video_call_rounded, 'Online presentation'),
                            const SizedBox(width: 8),
                            _buildTemplateCard(context, 'Hackathon', Icons.code_rounded, 'Coding event'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 'All', 'all', selectedCategory.value, () {
                      selectedCategory.value = 'all';
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Meetings', 'meeting', selectedCategory.value, () {
                      selectedCategory.value = 'meeting';
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Workshops', 'workshop', selectedCategory.value, () {
                      selectedCategory.value = 'workshop';
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Social', 'social', selectedCategory.value, () {
                      selectedCategory.value = 'social';
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'Webinars', 'webinar', selectedCategory.value, () {
                      selectedCategory.value = 'webinar';
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Time Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeFilterChip(context, 'Upcoming', 'upcoming', selectedFilter.value, () {
                      selectedFilter.value = 'upcoming';
                    }),
                    const SizedBox(width: 8),
                    _buildTimeFilterChip(context, 'Past', 'past', selectedFilter.value, () {
                      selectedFilter.value = 'past';
                    }),
                    const SizedBox(width: 8),
                    _buildTimeFilterChip(context, 'All', 'all', selectedFilter.value, () {
                      selectedFilter.value = 'all';
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Events List
        Expanded(
          child: _buildEventsList(context, ref, searchQuery.value, selectedCategory.value, selectedFilter.value, isGridView.value),
        ),
      ],
    );
  }

  Widget _buildEventsList(BuildContext context, WidgetRef ref, String searchQuery, String selectedCategory, String selectedFilter, bool isGridView) {
    // Use real events data from Firestore
    final eventsAsync = ref.watch(communityEventsProvider(community.id));
    
    return eventsAsync.when(
      data: (events) {
        // Apply filters
        List<EventModel> filteredEvents = events;
        
        // Search filter
        if (searchQuery.isNotEmpty) {
          filteredEvents = events.where((event) =>
            event.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            event.description.toLowerCase().contains(searchQuery.toLowerCase())
          ).toList();
        }
        
        // Category filter
        if (selectedCategory != 'all') {
          filteredEvents = filteredEvents.where((event) =>
            event.category == selectedCategory
          ).toList();
        }
        
        // Time filter
        final now = DateTime.now();
        switch (selectedFilter) {
          case 'upcoming':
            filteredEvents = filteredEvents.where((event) =>
              event.date.isAfter(now)
            ).toList();
            break;
          case 'past':
            filteredEvents = filteredEvents.where((event) =>
              event.date.isBefore(now)
            ).toList();
            break;
        }
        
        if (filteredEvents.isEmpty) {
          return _buildNoResultsState(context, searchQuery);
        }
        
        if (isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              return _buildEventGridCard(context, event, ref);
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              return _buildEventCard(context, event, ref);
            },
          );
        }
      },
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
            const SizedBox(height: 16),
            Text(
              'Error loading events',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, String title, IconData icon, String description) {
    return GestureDetector(
      onTap: () => _createEventFromTemplate(context, title),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, String selectedValue, VoidCallback onTap) {
    return CommunityDetailsWidgets.buildFilterChip(context, label, value, selectedValue, onTap);
  }

  Widget _buildTimeFilterChip(BuildContext context, String label, String value, String selectedValue, VoidCallback onTap) {
    final isSelected = value == selectedValue;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event, WidgetRef ref) {
    final now = DateTime.now();
    final isUpcoming = event.date.isAfter(now);
    final isPast = event.date.isBefore(now);
    final isOngoing = event.date.isBefore(now) && (event.endDate?.isAfter(now) ?? false);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getCategoryColor(event.category ?? 'meeting').withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(event.category ?? 'meeting'),
            color: _getCategoryColor(event.category ?? 'meeting'),
            size: 24,
          ),
        ),
        title: Text(
          event.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatEventTime(event.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(isUpcoming, isPast, isOngoing).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(isUpcoming, isPast, isOngoing),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(isUpcoming, isPast, isOngoing),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          onSelected: (value) => _handleEventAction(context, value, event),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility_outlined),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit Event'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share_outlined),
                title: Text('Share Event'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete Event', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _viewEventDetails(context, event),
      ),
    );
  }

  Widget _buildEventGridCard(BuildContext context, EventModel event, WidgetRef ref) {
    final now = DateTime.now();
    final isUpcoming = event.date.isAfter(now);
    final isPast = event.date.isBefore(now);
    final isOngoing = event.date.isBefore(now) && (event.endDate?.isAfter(now) ?? false);
    
    return GestureDetector(
      onTap: () => _viewEventDetails(context, event),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category icon and status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCategoryColor(event.category ?? 'meeting').withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(event.category ?? 'meeting'),
                    color: _getCategoryColor(event.category ?? 'meeting'),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      EventModel.getCategoryDisplayName(event.category ?? 'meeting'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(event.category ?? 'meeting'),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUpcoming 
                          ? Colors.green.withValues(alpha: 0.1)
                          : isPast 
                              ? Colors.grey.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUpcoming ? 'Upcoming' : isPast ? 'Past' : 'Ongoing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isUpcoming 
                            ? Colors.green
                            : isPast 
                                ? Colors.grey
                                : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatEventTime(event.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, String searchQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _createEvent(BuildContext context, WidgetRef ref, CommunityModel community) {
    // Use centralized logic for event creation
    CommunityDetailsLogic.handleCreateEvent(context, ref, community);
  }

  void _createEventFromTemplate(BuildContext context, String template) {
    // Create template data based on the selected template
    final templateData = _getTemplateData(template);
    
    // Navigate to event creation screen with template data
    NavigationService.navigateToCreateEvent(
      communityId: community.id,
      templateData: templateData,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating event from $template template...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Map<String, dynamic> _getTemplateData(String template) {
    switch (template.toLowerCase()) {
      case 'meeting':
        return {
          'title': 'Community Meeting',
          'description': 'Regular community meeting to discuss updates and plan future events.',
          'category': EventModel.categoryMeeting,
          'duration': 60, // minutes
          'maxSpots': null,
          'approvalRequired': false,
          'visibility': 'public',
        };
      case 'workshop':
        return {
          'title': 'Educational Workshop',
          'description': 'Learn new skills and share knowledge with community members.',
          'category': EventModel.categoryWorkshop,
          'duration': 120, // minutes
          'maxSpots': 20,
          'approvalRequired': true,
          'visibility': 'public',
        };
      case 'social':
        return {
          'title': 'Social Gathering',
          'description': 'Casual meetup to network and socialize with community members.',
          'category': EventModel.categorySocial,
          'duration': 90, // minutes
          'maxSpots': null,
          'approvalRequired': false,
          'visibility': 'public',
        };
      case 'webinar':
        return {
          'title': 'Online Webinar',
          'description': 'Virtual presentation or discussion on relevant topics.',
          'category': EventModel.categoryWebinar,
          'duration': 60, // minutes
          'maxSpots': 50,
          'approvalRequired': true,
          'visibility': 'public',
        };
      case 'hackathon':
        return {
          'title': 'Coding Event',
          'description': 'Collaborative coding session to build projects together.',
          'category': EventModel.categoryHackathon,
          'duration': 240, // minutes
          'maxSpots': 30,
          'approvalRequired': true,
          'visibility': 'public',
        };
      default:
        return {
          'title': 'New Event',
          'description': 'Create a new event for the community.',
          'category': EventModel.categoryMeeting,
          'duration': 60,
          'maxSpots': null,
          'approvalRequired': false,
          'visibility': 'public',
        };
    }
  }

  void _viewEventDetails(BuildContext context, EventModel event) {
    // Navigate to event details screen
    NavigationService.navigateToEventDetails(event.id, communityId: community.id);
  }

  void _handleEventAction(BuildContext context, String action, EventModel event) {
    switch (action) {
      case 'view':
        _viewEventDetails(context, event);
        break;
      case 'edit':
        // Navigate to edit event screen
        NavigationService.navigateToEditEvent(event, community);
        break;
      case 'share':
        // TODO: Share event
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing ${event.title}'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'delete':
        // TODO: Delete event with confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleting ${event.title}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  Color _getCategoryColor(String category) {
    return EventModel.getCategoryColor(category);
  }

  IconData _getCategoryIcon(String category) {
    return EventModel.getCategoryIcon(category);
  }

  Color _getStatusColor(bool isUpcoming, bool isPast, bool isOngoing) {
    if (isOngoing) return Colors.green;
    if (isUpcoming) return Colors.blue;
    if (isPast) return Colors.grey;
    return Colors.grey;
  }

  String _getStatusText(bool isUpcoming, bool isPast, bool isOngoing) {
    if (isOngoing) return 'LIVE';
    if (isUpcoming) return 'UPCOMING';
    if (isPast) return 'PAST';
    return 'UNKNOWN';
  }

  String _formatEventTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d from now';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h from now';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m from now';
    } else {
      return 'Starting now';
    }
  }
} 