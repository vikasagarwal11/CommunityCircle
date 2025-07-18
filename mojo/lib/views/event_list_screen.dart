import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/navigation_service.dart';
import '../core/theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../services/event_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class EventListScreen extends ConsumerStatefulWidget {
  final String? communityId; // Optional: if null, shows all accessible events

  const EventListScreen({
    super.key,
    this.communityId,
  });

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  final Logger _logger = Logger('EventListScreen');
  final EventService _eventService = EventService();
  
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      
      if (widget.communityId != null) {
        // Load events for specific community
        _events = await _eventService.getCommunityEvents(widget.communityId!, currentUser);
      } else {
        // Load all accessible events
        _events = await _eventService.getAccessibleEvents(currentUser);
      }
      
      _logger.i('🎬 Loaded ${_events.length} events');
    } catch (e) {
      _logger.e('❌ Error loading events: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.communityId != null ? 'Community Events' : 'All Events',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => NavigationService.navigateToCalendar(communityId: widget.communityId),
            tooltip: 'Calendar View',
          ),
          if (widget.communityId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateEventDialog,
            ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: widget.communityId == null ? FloatingActionButton(
        onPressed: _showCreateEventOptions,
        child: const Icon(Icons.add),
        tooltip: 'Create Event',
      ) : null,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return CustomErrorWidget(
        message: _error!,
        onRetry: _loadEvents,
      );
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final currentUser = ref.read(currentUserProvider).value;
    var isDebug = false;
    assert(() {
      // Only true in debug mode
      isDebug = true;
      return true;
    }());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.communityId != null ? 'No events in this community' : 'No events available',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.communityId != null 
                ? 'Events created in this community will appear here'
                : 'Join communities to see their events or create your own!',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (currentUser == null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(height: 8),
                  const Text(
                    'Not logged in',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You need to log in to see and create events',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else if (isDebug) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_user, color: Colors.blue, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    'Logged in as ${currentUser.displayName ?? currentUser.id}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${currentUser.role}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (widget.communityId == null) ...[
            // Remove the green Create Event button from here
            TextButton.icon(
              onPressed: () => NavigationService.navigateToSearch(),
              icon: const Icon(Icons.search),
              label: const Text('Discover Communities'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            // Debug button for testing
            if (currentUser != null) TextButton.icon(
              onPressed: _createSampleEvents,
              icon: const Icon(Icons.science),
              label: const Text('Add Sample Events (Debug)'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final currentUser = ref.read(currentUserProvider).value;
    final userRsvpStatus = currentUser != null ? event.getUserRsvpStatus(currentUser.id) : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Poster
            if (event.posterUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    event.posterUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultPoster();
                    },
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title and Visibility Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildVisibilityBadge(event),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Event Date and Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatEventDate(event.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Event Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // User RSVP Status (if any)
                  if (userRsvpStatus != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRsvpStatusColor(userRsvpStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getRsvpStatusColor(userRsvpStatus).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRsvpStatusIcon(userRsvpStatus),
                            size: 14,
                            color: _getRsvpStatusColor(userRsvpStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getRsvpStatusText(userRsvpStatus),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getRsvpStatusColor(userRsvpStatus),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Event Stats
                  Row(
                    children: [
                      _buildStatItem(
                        Icons.people,
                        '${event.goingCount} going',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      if (event.interestedCount > 0)
                        _buildStatItem(
                          Icons.help_outline,
                          '${event.interestedCount} interested',
                          Colors.orange,
                        ),
                      if (event.waitlistCount > 0) ...[
                        const SizedBox(width: 12),
                        _buildStatItem(
                          Icons.schedule,
                          '${event.waitlistCount} waitlist',
                          Colors.purple,
                        ),
                      ],
                      const Spacer(),
                      if (event.hasSpotsLimit) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.isFull 
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.isFull ? 'Full' : '${event.availableSpots} spots left',
                            style: TextStyle(
                              fontSize: 10,
                              color: event.isFull ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (event.isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Past',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Upcoming',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
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

  Widget _buildDefaultPoster() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.event,
          size: 48,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge(EventModel event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: event.isPublic 
            ? Colors.blue.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        event.isPublic ? 'Public' : 'Private',
        style: TextStyle(
          fontSize: 12,
          color: event.isPublic ? Colors.blue : Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference == 1) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else if (difference > 1) {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _navigateToEventDetails(EventModel event) {
    NavigationService.navigateToEventDetails(event.id, communityId: event.communityId);
  }

  void _showCreateEventDialog() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create events')),
      );
      return;
    }

    // Check if user can create events
    _eventService.canCreateEvent(widget.communityId!, currentUser).then((canCreate) {
      if (canCreate) {
        NavigationService.navigateToCreateEvent(widget.communityId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to create events in this community'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showCreateEventOptions() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create events')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event), // Use event icon for consistency
              title: const Text('In a Community'),
              subtitle: const Text('Create event in an existing community'),
              onTap: () {
                Navigator.pop(context);
                _showCommunitySelection();
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create Community + Event'),
              subtitle: const Text('Start a new community with an event'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToCreateCommunity();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCommunitySelection() {
    // For now, navigate to search to find communities
    // In a full implementation, you'd show a list of user's communities
    NavigationService.navigateToSearch();
  }

  Future<void> _createSampleEvents() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create sample events')),
      );
      return;
    }

    try {
      final communityId = widget.communityId;
      if (communityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample events can only be created in a community')),
        );
        return;
      }

             final sampleEvents = [
         EventModel(
           id: 'sample_1',
           communityId: communityId,
           title: 'Sample Event 1',
           description: 'This is a sample event for testing purposes.',
           date: DateTime.now().add(const Duration(days: 1)),
           location: 'Sample Location 1',
           creatorUid: currentUser.id,
           visibility: 'public',
           approvalRequired: false,
           createdAt: DateTime.now(),
           rsvps: {},
           checkIns: {},
         ),
         EventModel(
           id: 'sample_2',
           communityId: communityId,
           title: 'Sample Event 2',
           description: 'This is another sample event for testing purposes.',
           date: DateTime.now().add(const Duration(days: 2)),
           location: 'Sample Location 2',
           creatorUid: currentUser.id,
           visibility: 'private',
           approvalRequired: false,
           createdAt: DateTime.now(),
           rsvps: {},
           checkIns: {},
         ),
       ];

      for (final event in sampleEvents) {
        await _eventService.createEvent(event, currentUser);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample events created successfully!')),
      );
      _loadEvents(); // Refresh the list to show new events
    } catch (e) {
      _logger.e('❌ Error creating sample events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create sample events: ${e.toString()}')),
      );
    }
  }

  Color _getRsvpStatusColor(String status) {
    switch (status) {
      case EventModel.rsvpGoing:
        return Colors.green;
      case EventModel.rsvpInterested:
        return Colors.orange;
      case EventModel.rsvpNotGoing:
        return Colors.red;
      case EventModel.rsvpWaitlist:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRsvpStatusIcon(String status) {
    switch (status) {
      case EventModel.rsvpGoing:
        return Icons.check_circle;
      case EventModel.rsvpInterested:
        return Icons.help_outline;
      case EventModel.rsvpNotGoing:
        return Icons.cancel;
      case EventModel.rsvpWaitlist:
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _getRsvpStatusText(String status) {
    switch (status) {
      case EventModel.rsvpGoing:
        return 'Going';
      case EventModel.rsvpInterested:
        return 'Interested';
      case EventModel.rsvpNotGoing:
        return 'Not Going';
      case EventModel.rsvpWaitlist:
        return 'Waitlist';
      default:
        return 'Unknown';
    }
  }
} 